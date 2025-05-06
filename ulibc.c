/**
** @file	ulibc.c
**
** @author	numerous CSCI-452 classes
**
** @brief	C implementations of user-level library functions.
*/

#include <common.h>

#include <lib.h>

/*
**********************************************
** MEMORY MANIPULATION FUNCTIONS
**********************************************
*/

#include <usercode/ublkmov.c>
#include <usercode/umemclr.c>
#include <usercode/umemcpy.c>
#include <usercode/umemmove.c>
#include <usercode/umemset.c>

/*
**********************************************
** STRING MANIPULATION FUNCTIONS
**********************************************
*/

#include <usercode/upad.c>
#include <usercode/upadstr.c>
#include <usercode/usprint.c>
#include <usercode/ustr2int.c>
#include <usercode/ustrcat.c>
#include <usercode/ustrcmp.c>
#include <usercode/ustrcpy.c>
#include <usercode/ustrlen.c>

/*
**********************************************
** CONVERSION FUNCTIONS
**********************************************
*/

#include <usercode/ubound.c>
#include <usercode/ucvtdec.c>
#include <usercode/ucvtdec0.c>
#include <usercode/ucvthex.c>
#include <usercode/ucvtoct.c>
#include <usercode/ucvtuns.c>
#include <usercode/ucvtuns0.c>
#include <usercode/itoa.c>

/*
**********************************************
** CONVENIENT "SHORTHAND" VERSIONS OF SYSCALLS
**********************************************
*/

#include <usercode/uextras.c>
