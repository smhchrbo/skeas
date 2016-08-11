#
#EAS系统数据统计
#EAS系统维护后数据导出excel
#excel数据导入至mysql
#
setwd("~/R/rwd")
dbcon <- read.csv("db.csv",header = T,stringsAsFactors = F)

setwd("~/R/rwd/skeas")
if(require(RMySQL)&require(reshape)&require(dplyr)){
  con <- dbConnect(RMySQL::MySQL(), 
                   host = dbcon$host,
                   user = dbcon$user, 
                   password = dbcon$password,
                   db=dbcon$db)
  
stmt1<-"SELECT * FROM eas_v01_ry" 
stmt2<-"SELECT * FROM eas_v02_yh"

  #dbListTables(con)
  dbGetQuery(con,"SET NAMES UTF8")
  #所有人员
  ry <- dbGetQuery(con,stmt1)
  #医护人员
  yh <- dbGetQuery(con,stmt2)
  
  dbDisconnect(con)
  #summary(dbry)
  #summary(dbyh)
  detach("package:RMySQL", unload=TRUE)
}

#按用工方式分
ry.ygfs<-cast(ry,报表期间~用工方式,sum,value = "人数")
ry.ygfs<-transform(ry.ygfs,总人数=在编+直接支付工资的劳务派遣人员+住院医师培养生)

#按人员类别分
ry.lb<-cast(ry,报表期间~人员类型,sum,value = "人数")
#添加卫技列
ry.lb<-transform(ry.lb,卫技=医生+药剂+护士+医技)

#排除医生、护士、医技、药剂列(医护列另外计算)
ry.lb<-ry.lb[!(names(ry.lb) %in% c("医生","护士","医技","药剂"))]

#第1次合并
tb1 <- dplyr::left_join(ry.ygfs,ry.lb,by ="报表期间")

#计算医生护士数
yh.yshs<-cast(yh,报表期间~人员类型,sum,value = "人数")

#第2次合并
tb1 <- dplyr::left_join(tb1,yh.yshs,by ="报表期间")

#医生护士学历
yshsxl <- sqldf::sqldf("select 报表期间,人员类型,最高学历,sum(人数) as 学历 from yh group by 报表期间,最高学历,人员类型")
yshsxl <- yshsxl[yshsxl$最高学历!='专科以下',] 
yshsxl <- cast(yshsxl,报表期间~人员类型+最高学历,value = "学历",sum)
names(yshsxl) <- c("报表期间","护士本科学历","护士研究生学历","护士专科学历","医生本科学历","医生研究生学历")
#第3次合并
tb1 <- dplyr::left_join(tb1,yshsxl,by ="报表期间")

#医生护士硕士博士学位
yshsxw <- sqldf::sqldf("select 报表期间,人员类型,最高学位,sum(人数) as 研究生学位 from yh group by 报表期间,人员类型,最高学位")
yshsxw <- na.omit(yshsxw)
yshsxw <- cast(yshsxw,报表期间~人员类型+最高学位,value = "研究生学位",sum)
names(yshsxw) <- c("报表期间","护士硕士学位","医生博士学位","医生硕士学位")
#第4次合并
tb1 <- dplyr::left_join(tb1,yshsxw,by ="报表期间")


#write2excel
system.time(write.xlsx2(tb1,'eas.xlsx',sheetName='bmgz',row.names=FALSE))
