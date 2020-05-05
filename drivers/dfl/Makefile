EXTRA_CFLAGS += -std=gnu99

# We can't enable as many warnings as I'd like for the kernel, but let's see
# what we can do.
EXTRA_CFLAGS += -Werror
EXTRA_CFLAGS += -Wextra
EXTRA_CFLAGS += -Wall

EXTRA_CFLAGS += -Wundef
EXTRA_CFLAGS += -Wcast-align
EXTRA_CFLAGS += -Wmissing-prototypes
EXTRA_CFLAGS += -Wmissing-declarations
EXTRA_CFLAGS += -Wstrict-prototypes

# # Suppress some kernel error messages
EXTRA_CFLAGS += -Wno-declaration-after-statement
EXTRA_CFLAGS += -Wno-unused-parameter
# EXTRA_CFLAGS += -Wno-missing-field-initializers
EXTRA_CFLAGS += -Wno-sign-compare

# This one is particularly alarming to disable, but we get a *lot* of cast-align
# warnings from kernel.h.
EXTRA_CFLAGS += -Wno-cast-align

obj-m := dls_fpga_loader.o
dls_fpga_loader-objs += dfl_core.o
