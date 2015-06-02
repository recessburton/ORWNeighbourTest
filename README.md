Author:YTC 
Mail:recessburton@gmail.com
Created Time: 2015.6.1

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

Description：
	Telosb 上层模拟实现的ORW邻居关系建立过程测试程序.（仅做TOSSIM仿真）
	每个节点各自发送hello包，接收其它节点回复的ack包，计算“链路质量”，
	据此排序选择邻居加入邻居set,并打印邻居节点信息（set）.
	#每个节点周期性发送HeartBeat包申明自身的活性.(未完成)
	TOSSIM仿真输出文件：src/simOUT
	
Logs：
	V0.1 完成基本功能，心跳包交互功能未完成
	
Known Bugs: 
		none.

