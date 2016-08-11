#
#EAS系统数据统计
#EAS系统维护后数据导出excel
#excel数据导入至mysql
#
setwd("~/R/rwd")
dbcon <- read.csv("db.csv",header = T,stringsAsFactors = F)

setwd("~/R/rwd/skeas")
if(require(RMySQL)&require(reshape)){
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
}

ry.cast1<-cast(ry,报表期间~人员类型,sum,value = "人数")
ry.cast2<-cast(ry,报表期间~用工方式,sum,value = "人数")
ry.agg<-cbind(ry.cast2,ry.cast1,row.names="报表期间")
ry.agg <- ry.agg[,-c(4,7,11)]

yh.cast1<-cast(yh,报表期间~人员类型,sum,value = "人数")
ry.agg <- cbind(ry.agg,yh.cast1,row.names="报表期间")
