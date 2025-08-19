ALTER TABLE `ffavors_integ`.`Application`
DROP CONSTRAINT `App_Report_ID_FK`;

ALTER TABLE `ffavors_integ`.`Application` 
ADD CONSTRAINT `App_Report_ID_FK`
  FOREIGN KEY (`Report_ID`)
  REFERENCES `ffavors_integ`.`Reports` (`Report_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Menus`
DROP CONSTRAINT `Menus_Report_ID_FK`;

ALTER TABLE `ffavors_integ`.`Menus` 
ADD CONSTRAINT `Menus_Report_ID_FK`
  FOREIGN KEY (`Report_ID`)
  REFERENCES `ffavors_integ`.`Reports` (`Report_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Menus`
DROP CONSTRAINT `Menus_App_ID_FK`;

ALTER TABLE `ffavors_integ`.`Menus` 
ADD CONSTRAINT `Menus_App_ID_FK`
  FOREIGN KEY (`App_ID`)
  REFERENCES `ffavors_integ`.`Application` (`App_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Reports`
DROP CONSTRAINT `Reports_Param_ID_FK`;

ALTER TABLE `ffavors_integ`.`Reports` 
ADD CONSTRAINT `Reports_Param_ID_FK`
  FOREIGN KEY (`Param_ID`)
  REFERENCES `ffavors_integ`.`Reports_Parameters` (`Param_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Reports_Sched_Param` 
ADD CONSTRAINT `RSP_Report_ID_FK`
  FOREIGN KEY (`Report_ID`)
  REFERENCES `ffavors_integ`.`Reports` (`Report_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Reports_Sched_Param` 
ADD CONSTRAINT `RSP_Param_ID_FK`
  FOREIGN KEY (`Param_ID`)
  REFERENCES `ffavors_integ`.`Reports_Parameters` (`Param_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Reports_Scheduler` 
ADD CONSTRAINT `Report_Sched_Report_ID_FK`
  FOREIGN KEY (`Report_ID`)
  REFERENCES `ffavors_integ`.`Reports` (`Report_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Reports_Scheduler` 
ADD CONSTRAINT `Report_Sched_Param_ID_FK`
  FOREIGN KEY (`Param_ID`)
  REFERENCES `ffavors_integ`.`Reports_Parameters` (`Param_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `ffavors_integ`.`Reports_Scheduler` 
ADD CONSTRAINT `Report_Sched_App_ID_FK`
  FOREIGN KEY (`App_ID`)
  REFERENCES `ffavors_integ`.`Application` (`App_ID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

