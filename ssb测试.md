# **完成 SSB 测试**

SSB 星型模式基准测试是 OLAP 数据库性能测试的常用场景，通过本篇教程，您可以了解到如何在 MatrixOne 中实现 SSB 测试。

通过阅读本教程，您将学习如何使用 MatrixOne Cloud 完成 SSB测试。

## **1. 生成数据**

使用wget命令下载 ssb工具包并解压，生成 ssb测试集， `scale factor=100`表示产生 100GB 的完整数据集，当使用 ` 1` 时会产生大约 1GB 的数据集，以此类推，默认生成100G数据，-c表示生成lineorder表数据的线程数，默认为10线程。

```
wget https://xxx/ssb.zip
unzip ssb
cd ssb

./bin/gen-ssb-data.sh -s 1
```

生成完整数据集可能需要一段时间。完成后，您可以看到结果文件。

```
-r-sr-S--T 1 root root  2837046 Jan 24 14:34 customer.tbl
-rw-r--r-- 1 root root   229965 Jan 24 14:34 date.tbl
-rw-r--r-- 1 root root 59349727 Jan 24 14:34 lineorder.tbl.1
-rw-r--r-- 1 root root 60070206 Jan 24 14:34 lineorder.tbl.10
-rw-r--r-- 1 root root 59549558 Jan 24 14:34 lineorder.tbl.2
-rw-r--r-- 1 root root 60016540 Jan 24 14:34 lineorder.tbl.3
-rw-r--r-- 1 root root 59967360 Jan 24 14:34 lineorder.tbl.4
-rw-r--r-- 1 root root 59994420 Jan 24 14:34 lineorder.tbl.5
-rw-r--r-- 1 root root 60141442 Jan 24 14:34 lineorder.tbl.6
-rw-r--r-- 1 root root 59931957 Jan 24 14:34 lineorder.tbl.7
-rw-r--r-- 1 root root 60052881 Jan 24 14:34 lineorder.tbl.8
-rw-r--r-- 1 root root 59974390 Jan 24 14:34 lineorder.tbl.9
-rw-r--r-- 1 root root 17139259 Jan 24 14:34 part.tbl
-rw-r--r-- 1 root root   166676 Jan 24 14:34 supplier.tbl

```

## **2. 在 MatrixOne 中建表**

修改配置文件 `conf/matrxione.conf`，指定MatrixOne Cloud的地址、用户名、密码，配置文件示例如下

```
# MatrixOne host
export HOST='127.0.0.1'
# MatrixOne port
export PORT=6001
# MatrixOne username
export USER='root'
# MatrixOne password
export PASSWORD='111'
# The database where SSB tables located
export DB='ssb'
```

然后执行以下脚本进行建表操作。

```
./bin/create-ssb-tables.sh
```

## **3. 导入数据**

执行以下脚本导入ssb测试所需数据，-c可以指定执行导入的线程数，默认为5个线程

```
./bin/load-ssb-data.sh
```

加载完成后，可以使用创建的表查询 MatrixOne 中的数据。

## **4. 运行查询命令**

### **多表查询**

```sql
./bin/run-ssb-queries.sh
```

### **单表查询**

```
./bin/run-ssb-flat-queries.sh
```

## **5. 运行结果示例**

**单表查询结果**

| 查询  | 第一次 | 第二次 | 第三次 | 最快      |
| ----- | ------ | ------ | ------ | --------- |
| q1.1: | 0.24   | 0.06   | 0.07   | fast:0.06 |
| q1.2: | 0.08   | 0.07   | 0.08   | fast:0.07 |
| q1.3: | 0.07   | 0.07   | 0.06   | fast:0.06 |
| q2.1: | 0.2    | 0.11   | 0.11   | fast:0.11 |
| q2.2: | 0.08   | 0.1    | 0.1    | fast:0.08 |
| q2.3: | 0.26   | 0.29   | 0.27   | fast:0.26 |
| q3.1: | 0.17   | 0.14   | 0.13   | fast:0.13 |
| q3.2: | 0.07   | 0.07   | 0.07   | fast:0.07 |
| q3.3: | 0.06   | 0.06   | 0.05   | fast:0.05 |
| q3.4: | 0.05   | 0.06   | 0.05   | fast:0.05 |
| q4.1: | 0.19   | 0.16   | 0.17   | fast:0.16 |
| q4.2: | 0.19   | 0.17   | 0.16   | fast:0.16 |
| q4.3: | 0.34   | 0.08   | 0.07   | fast:0.07 |

**多表查询结果**

| 查询  | 第一次 | 第二次 | 第三次 | 最快      |
| ----- | ------ | ------ | ------ | --------- |
| q1.1: | 0.16   | 0.07   | 0.05   | fast:0.05 |
| q1.2: | 0.06   | 0.06   | 0.06   | fast:0.06 |
| q1.3: | 0.06   | 0.06   | 0.06   | fast:0.06 |
| q2.1: | 0.24   | 0.08   | 0.07   | fast:0.07 |
| q2.2: | 0.08   | 0.09   | 0.08   | fast:0.08 |
| q2.3: | 0.05   | 0.04   | 0.05   | fast:0.04 |
| q3.1: | 0.24   | 0.15   | 0.49   | fast:0.15 |
| q3.2: | 0.21   | 0.17   | 0.2    | fast:0.17 |
| q3.3: | 0.09   | 0.09   | 0.07   | fast:0.07 |
| q3.4: | 0.07   | 0.06   | 0.08   | fast:0.06 |
| q4.1: | 0.48   | 0.26   | 0.26   | fast:0.26 |
| q4.2: | 0.62   | 0.29   | 0.29   | fast:0.29 |
| q4.3: | 0.52   | 0.21   | 0.15   | fast:0.15 |

