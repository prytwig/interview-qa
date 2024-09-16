# MySQL "server has gone away" 错误排查方案

1. 可尝试将 Haproxy，Mysql 的日志级别调整为 debug 级别，以获取更详细的错误信息
2. 通过 zabbix, prometheus 等工具监控系统资源和网络链路，排除CPU瓶颈，IO瓶颈，网络抖动等问题
3. 调整 mysql *wait_timeout*、*max_connections* 等相关的性能参数，排除 mysql 设置问题
4. 调整 haproxy *timeout server*、*timeout client* 等相关性能参数，确保与 mysql 配置一致
5. 协助开发审查代码，应用程序是否有 *timeout* 参数可进行调整
6. 此外也有低概率的 硬件故障、操作系统 Bug，Mysql Bug、HAProxy Bug 的可能性，需要进一步深入学习排查
