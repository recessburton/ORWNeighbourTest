/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-06-01 15:29
 
 @author: ytc recessburton@gmail.com
 @version: 1.0
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 **/

#include <Timer.h>
#include "ORWNeighbourTest.h"

module ORWNeighbourTestC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
}

implementation {

	NeighbourUnit neighbourSet[10*MAX_NEIGHBOUR_NUM];
	message_t pkt;
	volatile bool busy = FALSE;
	uint8_t helloMsgCount = 0;
	uint8_t neighbourNumIndex = 0;//邻居数目，>从0开始!<<<<<<
	int tempIndex;

	event void Boot.booted() {
		dbg("NodesInfo", "Booted @ %s.\n", sim_time_string());
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	void helloMsgSend() {
		if( ! busy) {
			NeighbourMsg * btrpkt = (NeighbourMsg * )(call Packet.getPayload(&pkt, sizeof(NeighbourMsg)));
			if(btrpkt == NULL) {
				return;
			}
			btrpkt->dstid = 0xFFFF;
			btrpkt->sourceid = TOS_NODE_ID;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NeighbourMsg)) == SUCCESS) {
				busy = TRUE;
				dbg("AMInfo","sending HELLO...\n");
			}
		}
	}

	event void Timer0.fired() {
		if (helloMsgCount > 10 && helloMsgCount < 15){
			helloMsgSend();
			helloMsgCount ++;
		}
		else if(helloMsgCount <= 10)
			helloMsgCount ++;
		else
			call Timer0.stop();
	}

	event void AMSend.sendDone(message_t * msg, error_t err) {
		if(&pkt == msg) {
			busy = FALSE;
		}
	}
	
	void ackMsgSend(uint16_t sourceid) {
		if( ! busy) {
			NeighbourMsg * btrpkt1 = (NeighbourMsg * )(call Packet.getPayload(&pkt,sizeof(NeighbourMsg)));
			if(btrpkt1 == NULL) {
				return;
			}
			btrpkt1->dstid = sourceid;
			btrpkt1->sourceid = TOS_NODE_ID;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NeighbourMsg)) == SUCCESS) {
				busy = TRUE;
				dbg("AMInfo","send ACK to %d done.\n", sourceid);
			}
		}
	}
	
	void addSet(uint16_t sourceid){
		int i;
		for(i = 0 ; i <= neighbourNumIndex; i++ ){
			if(neighbourSet[i].nodeid == sourceid){
				return;
			}else{
				continue;
			}
		}
		//如果执行到此处，表明该节点不在邻居集合中
		neighbourNumIndex ++;
		neighbourSet[neighbourNumIndex].nodeid = sourceid;
		neighbourSet[neighbourNumIndex].linkquality = 0.0f;
		neighbourSet[neighbourNumIndex].recvCount = 0;
	}
	
	void sortNodes(int left, int right){
		//邻居节点集中按照链路质量快速排序
		int i, j;
		NeighbourUnit temp, t;
		
		if(left > right) 
			return;	
		
		memcpy(&temp, &neighbourSet[left], sizeof(NeighbourUnit));
		i = left;
		j = right;
		
		while(i != j) {
			while(neighbourSet[j].linkquality <= temp.linkquality && i < j)
				j --;
			while(neighbourSet[i].linkquality <= temp.linkquality && i < j)
				i ++;	
				
			if(j < j) {
				memcpy(&t, &neighbourSet[i], sizeof(NeighbourUnit));
				memcpy(&neighbourSet[i], &neighbourSet[j],  sizeof(NeighbourUnit));
				memcpy(&neighbourSet[j], &t,   sizeof(NeighbourUnit));	
			}
		}
		
		memcpy(&neighbourSet[left], &neighbourSet[i], sizeof(NeighbourUnit));
		memcpy(&neighbourSet[i], &temp, sizeof(NeighbourUnit));
		
		sortNodes(left, i-1);
		sortNodes(i+1, right);

	}
	
	void estLinkQuality(uint16_t sourceid){
		int i = 0;
		for( ; i <= neighbourNumIndex; i++ ){
			if(neighbourSet[i].nodeid == sourceid){
				neighbourSet[i].recvCount ++;
				neighbourSet[i].linkquality = (float) (neighbourSet[i].recvCount / (helloMsgCount * 1.0));
			}else{
				continue;
			}
		}
		sortNodes(0, neighbourNumIndex);
		dbg("NodesInfo","neighbourSet sorts done.\n");
	}
	
	event message_t * Receive.receive(message_t * msg, void * payload,uint8_t len) {
		int i;
		if(len == sizeof(NeighbourMsg)) {
			NeighbourMsg * btrpkt = (NeighbourMsg * ) payload;
			if(btrpkt->dstid == 0xFFFF){	//接到其它节点发的hello包，回ack包
				dbg("AMInfo","received HELLO, sending ACK to %d...\n",btrpkt->sourceid);
				ackMsgSend(btrpkt->sourceid);
			}
			else if ( (btrpkt->dstid - TOS_NODE_ID) == 0) {	//接到的是自己的回包，计算链路质量，判断邻居资格
				dbg("AMInfo","received ACK from %d, estimating\n", btrpkt->sourceid);
				addSet(btrpkt->sourceid);
				estLinkQuality(btrpkt->sourceid);
				dbg("Neighbour","\nHAS NEIGHBOURS:");
				for(i = 0; i<=MAX_NEIGHBOUR_NUM; i++ ){
					if(neighbourSet[i].linkquality > 0)
						dbg("Neighbour","%d with linkQ %f\n", neighbourSet[i].nodeid, neighbourSet[i].linkquality);
				}
				dbg("Neighbour","\n");
			}else{	//其它包，丢弃
				//dbg("AMInfo","received OTHER MSG, from %d to %d, DISCARDING...\n",btrpkt->sourceid, btrpkt->dstid);
			}
		}
		return msg;
	}
}