/**
** @file	userids.h
**
** @author	Warren R. Carithers
**
** @brief	IDs for user-level programs
*/

#ifndef USERIDS_H_
#define USERIDS_H_

/*
** These IDs are used to identify the various user programs.
** Each call to exec() will provide one of these as the first
** argument.
**
** This list should be updated if/when the collection of
** user processes changes.
*/
enum users_e {
	// These are started by the system
	Init,
	// These are started by the initial user process
	Idle, Shell,
	// The rest are started from the shell or from
	// other user-level processes
	ProgABC, ProgDE, ProgFG, ProgH, ProgI, ProgJ, ProgKL,
	ProgMN, ProgP, ProgQ, ProgR, ProgS, ProgTUV, ProgW,
	ProgX, ProgY, ProgZ
	// sentinel
	, N_USERS
};

#endif
