/**
** @file	lib.h
**
** @author	Numerous CSCI-452 classes
**
** @brief	C declarations of common library functions
**
** These are callable from either kernel or user code. Care should be taken
** that user code is linked against these separately from kernel code, to
** ensure separation of the address spaces.
*/

#ifndef LIB_H_
#define LIB_H_

#include <common.h>

/*
** Pull in the level-specific library headers
*/
#ifdef KERNEL_SRC
#include <klib.h>
#else
#include <ulib.h>
#endif  /* KERNEL_SRC */

#endif
