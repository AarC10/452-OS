/**
** @file	itoa.c
**
** @author	John Arrandale
**
** @brief	C implementation of itoa
*/

#ifndef IOTA_SRC_INC
#define IOTA_SRC_INC

#include <common.h>

#include <lib.h>

/**
** itoa(num,str,base)
**
** converts an interger value to a null-terminated string using
** the specified base and stores the result in the given array
**
** @param num	Value to convert
** @param str	String buffer
** @param base	Numerical base used to represent the value
**
** @return A pointer to the resulting null-terminated string
**
** NOTE:  assumes str is large enough to hold the resulting string
**
** Algorithm inspired from: https://geeksforgeeks.org/implement-itoa
*/
char *itoa( int num, char *str, int base ) {
	int i = 0;

	bool_t negative = false;

	if (num == 0) {
		str[i++] = '0';
		str[i] = '\0';

		return str;
	}

	if (num < 0 && base == 10) {
		negative = true;
		num = -num;
	}

	while (num != 0) {
		int rem = num % base;

		str[i++] = (rem > 9) ? (rem - 10) + 'a' : rem + '0';
		num = num / base;
	}

	if (negative) str[i++] = '-';

	str[i] = '\0';

	int start = 0;
	int end = i - 1;

	while (start < end) {
		char tmp = str[start];
		
		str[start] = str[end];
		str[end] = tmp;

		end--;
		start++;
	}

	return str;
}

#endif
