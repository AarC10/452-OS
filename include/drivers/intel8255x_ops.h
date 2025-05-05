#ifndef _INTEL8255X_OPS_
#define _INTEL8255X_OPS_

#include <types.h>

int i8255x_ops_read_reg(const uint32_t offset);

int i8255x_ops_write_reg(const uint32_t offset, const uint32_t value);

#endif // _INTEL8255X_OPS_
