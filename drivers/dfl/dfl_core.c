#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/of.h>
#include <linux/gpio/consumer.h>
#include <linux/time.h>
#include <linux/delay.h>
#include <linux/uaccess.h>

#define MAX_BUFFER_SIZE (128)
#define MAX_DEV_NAME_SIZE (32)
#define GPIO_TIMEOUT_MS (1000)

struct dfl_data {
    char name[MAX_DEV_NAME_SIZE];
    struct mutex mutex;
    struct miscdevice miscdev;
    struct gpio_desc *init_gpio;
    struct gpio_desc *done_gpio;
    struct gpio_desc *prog_gpio;
    struct gpio_desc *d0_gpio;
    struct gpio_desc *clk_gpio;
};

static inline struct dfl_data *to_dfl_data(struct file *file)
{
    struct miscdevice *misc = file->private_data;
    return container_of(misc, struct dfl_data, miscdev);
}

static int wait_for_io(struct gpio_desc *io, int eval, int sleep)
{
    int val;
    unsigned long timeout = jiffies + msecs_to_jiffies(GPIO_TIMEOUT_MS);
    do {
        val = gpiod_get_value(io);
        if (val == eval)
            break;
        if (sleep)
            msleep(10);
    } while (!time_after(jiffies, timeout));
    if (val != eval)
    {
        pr_err("gpio %p won't go to %d\n", io, eval);
        return -EIO;
    }
    return 0;
}

static int dfl_open(struct inode *inode, struct file *file)
{
    int rc;
    struct dfl_data *dfl = to_dfl_data(file);
    pr_info("Opening %s\n", dfl->miscdev.name);
    mutex_lock(&dfl->mutex);
    if (gpiod_direction_output(dfl->d0_gpio, 0))
    {
        rc = -EIO;
        pr_err("Error while setting data pin direction\n");
        goto err1;
    }
    if (gpiod_direction_output(dfl->clk_gpio, 0))
    {
        rc = -EIO;
        pr_err("Error while setting clk pin direction\n");
        goto err1;
    }

    gpiod_set_value(dfl->prog_gpio, 0);
    rc = wait_for_io(dfl->init_gpio, 0, 0);
    gpiod_set_value(dfl->prog_gpio, 1);
    if (rc)
        goto err1;
    rc = wait_for_io(dfl->init_gpio, 1, 1);
    if (rc)
        goto err1;
    return 0;

err1:
    mutex_unlock(&dfl->mutex);
    return rc;
}

static void clk(struct dfl_data *dfl)
{
    gpiod_set_value(dfl->clk_gpio, 1);
    gpiod_set_value(dfl->clk_gpio, 0);
}

static void send_data(struct dfl_data *dfl, char *buf, size_t size)
{
    for (size_t i = 0; i < size; i++)
    {
        for (int j = 7; j >= 0; j--)
        {
            gpiod_set_value(dfl->d0_gpio, (buf[i]>>j) & 1);
            clk(dfl);
        }
    }
}

static ssize_t dfl_write(
    struct file *file, const char __user *ubuf, size_t size, loff_t *off)
{
    struct dfl_data *dfl = to_dfl_data(file);
    char buf[MAX_BUFFER_SIZE];
    size_t ubuf_i = 0;
    while (ubuf_i < size)
    {
        size_t wsize = size - ubuf_i;
        if (wsize > MAX_BUFFER_SIZE)
            wsize = MAX_BUFFER_SIZE;
        if (copy_from_user(buf, ubuf + ubuf_i, wsize))
        {
            pr_err("Error while copying user data\n");
            return -EFAULT;
        }
        send_data(dfl, buf, wsize);
        if (!gpiod_get_value(dfl->init_gpio))
        {
            pr_err("Error while transfering data, init pin went low\n");
            return -EIO;
        }
        ubuf_i += wsize;
        *off += wsize;
    }
    return size;
}

static int dfl_release(struct inode *inode, struct file *file)
{
    int val;
    int rc = 0;
    struct dfl_data *dfl = to_dfl_data(file);
    pr_info("Closing %s\n", dfl->miscdev.name);
    for (int i = 0; i < 1000; i++)
    {
        val = gpiod_get_value(dfl->done_gpio);
        if (val == 1)
            break;
        clk(dfl);
    }
    if (val != 1)
    {
        pr_err("Done signal timed out\n");
        rc = -EIO;
    }
    if (gpiod_direction_input(dfl->d0_gpio))
        pr_err("Error while setting data pin direction\n");
    if (gpiod_direction_input(dfl->clk_gpio))
        pr_err("Error while setting clk pin direction\n");
    mutex_unlock(&dfl->mutex);
    return rc;
}

static struct file_operations dfl_fops = {
    .owner = THIS_MODULE,
    .open = dfl_open,
    .write = dfl_write,
    .release = dfl_release
};


static int dfl_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    struct device_node *np = dev->of_node;
    struct dfl_data *prv =
        devm_kzalloc(dev, sizeof(struct dfl_data), GFP_KERNEL);

    pr_info("Probing dls_fpga_loader\n");

    const char *name;
    int rc = of_property_read_string(np, "dev_name", &name);
    if (rc)
    {
        pr_err("Unable to get device name\n");
        return rc;
    }

    strncpy(prv->name, name, MAX_DEV_NAME_SIZE);
    prv->miscdev.name = prv->name;
    prv->miscdev.minor = MISC_DYNAMIC_MINOR;
    prv->miscdev.fops = &dfl_fops;
    prv->init_gpio = devm_gpiod_get(dev, "init", GPIOD_IN);
    mutex_init(&prv->mutex);

    if (IS_ERR(prv->init_gpio))
        return PTR_ERR(prv->init_gpio);
    prv->done_gpio = devm_gpiod_get(dev, "done", GPIOD_IN);
    if (IS_ERR(prv->done_gpio))
        return PTR_ERR(prv->done_gpio);
    prv->prog_gpio = devm_gpiod_get(dev, "prog", GPIOD_OUT_HIGH);
    if (IS_ERR(prv->prog_gpio))
        return PTR_ERR(prv->prog_gpio);
    prv->d0_gpio = devm_gpiod_get(dev, "d0", GPIOD_IN);
    if (IS_ERR(prv->d0_gpio))
        return PTR_ERR(prv->d0_gpio);
    prv->clk_gpio = devm_gpiod_get(dev, "clk", GPIOD_IN);
    if (IS_ERR(prv->clk_gpio))
        return PTR_ERR(prv->clk_gpio);

    rc = misc_register(&prv->miscdev);
    if (rc < 0)
    {
        pr_info("Could not register misc device\n");
        return rc;
    }
    platform_set_drvdata(pdev, prv);
    return 0;
}

static int dfl_remove(struct platform_device *pdev)
{
    struct dfl_data *prv = platform_get_drvdata(pdev);
    misc_deregister(&prv->miscdev);
    return 0;
}

static const struct of_device_id dfl_of_ids[] = {
    { .compatible = "dls,fpga_loader" },
    {}
};
MODULE_DEVICE_TABLE(of, dfl_of_ids);

static struct platform_driver dfl_platform_driver = {
    .probe = dfl_probe,
    .remove = dfl_remove,
    .driver = {
        .name = "dls_fpga_loader",
        .of_match_table = dfl_of_ids,
        .owner = THIS_MODULE
    }
};

module_platform_driver(dfl_platform_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Diamond Light Source Ltd");
