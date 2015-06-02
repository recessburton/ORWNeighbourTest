#ifndef ORWNEIGHBOUR_TEST_H
#define ORWNEIGHBOUR_TEST_H

enum {
  ORWNEIGHBOUR = 5,
  TIMER_PERIOD_MILLI = 1024,
  MAX_NEIGHBOUR_NUM = 5
};

typedef nx_struct NeighbourMsg {
	nx_uint16_t dstid;
	nx_uint16_t sourceid;
} NeighbourMsg;

typedef struct NeighbourUnit {
	uint16_t nodeid;
	float linkquality;
	uint8_t recvCount;
} NeighbourUnit;

#endif /* ORWNEIGHBOUR_TEST_H */
