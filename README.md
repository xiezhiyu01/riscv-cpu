Thinpad 模板工程
---------------

工程包含示例代码和所有引脚约束，可以直接编译。

代码中包含中文注释，编码为utf-8


Tips:
1. 尽量在译码阶段生成控制信号，例如内存读信号不要在mem阶段才用 mem_op == LW 生成，容易导致尖峰信号
2. Mix of synchronous and asynchronous control for register 不要在clk中用组合逻辑控制, 详见if_id.v中的branch_flag，不能写成 (rst || stall[1] == `Stop || branch_flag)