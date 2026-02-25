-- RTZ normal values seed for CSE reference table
-- Source file: /Users/joshguerrero/Desktop/RTZ Normal Values .pdf

begin;

delete from public.cse_reference_values
where source_name = 'RTZ Normal Values';

insert into public.cse_reference_values (source_name, source_revision, category, item_name, normal_text, low_value, high_value, unit, notes) values
('RTZ Normal Values','2026-02-21','Patient Assessment','Urine Output','40 mL/hour',40,40,'mL/hour',null),
('RTZ Normal Values','2026-02-21','Patient Assessment','Heart Rate','60-100 /min',60,100,'/min',null),
('RTZ Normal Values','2026-02-21','Patient Assessment','Blood Pressure','120/80 mmHg (range 90/60-140/90)',90,140,'mmHg systolic','diastolic range 60-90 mmHg'),
('RTZ Normal Values','2026-02-21','Patient Assessment','Intracranial Pressure','5-10 mmHg',5,10,'mmHg',null),
('RTZ Normal Values','2026-02-21','Patient Assessment','Cerebral Perfusion Pressure','70-90 mmHg',70,90,'mmHg',null),
('RTZ Normal Values','2026-02-21','Patient Assessment','Exhaled Carbon Monoxide','< 7 (nonsmokers)',null,7,'ppm','upper bound'),

('RTZ Normal Values','2026-02-21','CBC','Red Blood Cells (RBC)','4-6 mill/mm3',4,6,'mill/mm3',null),
('RTZ Normal Values','2026-02-21','CBC','Hemoglobin (Hb)','12-16 gm',12,16,'g/dL',null),
('RTZ Normal Values','2026-02-21','CBC','Hematocrit (Hct)','40-50 %',40,50,'%',null),
('RTZ Normal Values','2026-02-21','CBC','White Blood Cells','5,000-10,000 per mm3',5000,10000,'/mm3',null),

('RTZ Normal Values','2026-02-21','Chemistry','Potassium (K+)','3.5-4.5 mEq/L',3.5,4.5,'mEq/L',null),
('RTZ Normal Values','2026-02-21','Chemistry','Sodium (Na+)','135-145 mEq/L',135,145,'mEq/L',null),
('RTZ Normal Values','2026-02-21','Chemistry','Chloride (Cl-)','80-100 mEq/L',80,100,'mEq/L',null),
('RTZ Normal Values','2026-02-21','Chemistry','Bicarbonate (HCO3-)','22-26 mEq/L',22,26,'mEq/L',null),
('RTZ Normal Values','2026-02-21','Chemistry','Creatinine','0.7-1.3 mg/dL',0.7,1.3,'mg/dL',null),
('RTZ Normal Values','2026-02-21','Chemistry','Blood Urea Nitrogen (BUN)','8-25 mg/dL',8,25,'mg/dL',null),

('RTZ Normal Values','2026-02-21','Coagulation','Clotting Time','Up to 6 minutes',null,6,'minutes',null),
('RTZ Normal Values','2026-02-21','Coagulation','Platelet Count','150,000-400,000/mm3',150000,400000,'/mm3',null),
('RTZ Normal Values','2026-02-21','Coagulation','Activated Partial Thromboplastin Time','24-32 seconds',24,32,'seconds',null),
('RTZ Normal Values','2026-02-21','Coagulation','Prothrombin Time','12-15 seconds',12,15,'seconds',null),

('RTZ Normal Values','2026-02-21','Cardiac Enzymes','Troponin','< 0.1 ng/mL',null,0.1,'ng/mL',null),
('RTZ Normal Values','2026-02-21','Cardiac Enzymes','BNP','< 100 pg/mL',null,100,'pg/mL',null),

('RTZ Normal Values','2026-02-21','Hemodynamics','Mean Arterial Pressure (MAP)','93-94 mmHg',93,94,'mmHg',null),
('RTZ Normal Values','2026-02-21','Hemodynamics','Right Atrial Pressure / CVP','2-6 mmHg (4-12 cmH2O)',2,6,'mmHg','alt unit 4-12 cmH2O'),
('RTZ Normal Values','2026-02-21','Hemodynamics','Pulmonary Artery Pressure','25/8 mmHg (mean 13-14)',13,14,'mmHg mean',null),
('RTZ Normal Values','2026-02-21','Hemodynamics','PCWP','8-10 mmHg',8,10,'mmHg',null),
('RTZ Normal Values','2026-02-21','Hemodynamics','Cardiac Output','4-8 L/min',4,8,'L/min',null),
('RTZ Normal Values','2026-02-21','Hemodynamics','SVR','< 20 mmHg/L/min or 1600 dynes/sec/m-5',null,20,'mmHg/L/min','alt dynes value provided'),
('RTZ Normal Values','2026-02-21','Hemodynamics','PVR','< 2.5 mmHg/L/min or 200 dynes/sec/cm-5',null,2.5,'mmHg/L/min','alt dynes value provided'),
('RTZ Normal Values','2026-02-21','Hemodynamics','Cardiac Index','2.5-4 L/min/m2',2.5,4,'L/min/m2',null),

('RTZ Normal Values','2026-02-21','Monitoring','Pulse Oximetry','93-97 %',93,97,'%',null),
('RTZ Normal Values','2026-02-21','Monitoring','Capnography (EtCO2)','30 torr',30,30,'torr',null),
('RTZ Normal Values','2026-02-21','Monitoring','Carboxyhemoglobin (COHb)','0-1 %',0,1,'%',null),
('RTZ Normal Values','2026-02-21','Monitoring','ETT Cuff Pressure','20-25 mmHg',20,25,'mmHg',null),

('RTZ Normal Values','2026-02-21','ABG Adult','PaCO2','35-45 torr',35,45,'torr',null),
('RTZ Normal Values','2026-02-21','ABG Adult','PaO2','80-100 torr',80,100,'torr',null),
('RTZ Normal Values','2026-02-21','ABG Adult','pH','7.35-7.45',7.35,7.45,'pH',null),
('RTZ Normal Values','2026-02-21','ABG Adult','SaO2','95-100 %',95,100,'%',null),
('RTZ Normal Values','2026-02-21','ABG Adult','HCO3','22-26 mEq/L',22,26,'mEq/L',null),
('RTZ Normal Values','2026-02-21','ABG Adult','Base Excess','-2 to +2',-2,2,'mEq/L',null),

('RTZ Normal Values','2026-02-21','ABG Newborn','PaCO2','< 50 torr',null,50,'torr',null),
('RTZ Normal Values','2026-02-21','ABG Newborn','PaO2','> 60 torr',60,null,'torr',null),
('RTZ Normal Values','2026-02-21','ABG Newborn','pH','> 7.30',7.30,null,'pH',null),

('RTZ Normal Values','2026-02-21','Bedside Ventilatory Parameters','Vital Capacity (acceptable)','>= 10 mL/kg',10,null,'mL/kg','normal 65-75 mL/kg'),
('RTZ Normal Values','2026-02-21','Bedside Ventilatory Parameters','Respiratory Rate (acceptable)','8-20 /min',8,20,'/min',null),
('RTZ Normal Values','2026-02-21','Bedside Ventilatory Parameters','Minute Ventilation (acceptable)','< 10 L/min',null,10,'L/min','normal 5-6 L/min'),
('RTZ Normal Values','2026-02-21','Bedside Ventilatory Parameters','MIP/NIF (acceptable)','>= 20 cmH2O',20,null,'cmH2O','normal 80 cmH2O'),
('RTZ Normal Values','2026-02-21','Bedside Ventilatory Parameters','MEP (acceptable)','>= 40 cmH2O',40,null,'cmH2O','normal 160 cmH2O'),
('RTZ Normal Values','2026-02-21','Bedside Ventilatory Parameters','Spontaneous Tidal Volume (acceptable)','>= 5 mL/kg',5,null,'mL/kg',null),

('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Adult','Tidal Volume','5-10 mL/kg ideal body weight',5,10,'mL/kg',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Adult','Pressure Limit','<= 35 cmH2O',null,35,'cmH2O',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Adult','Respiratory Rate','10-20 breaths/min',10,20,'breaths/min',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Adult','FiO2','40-60 %',40,60,'%',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Adult','PEEP','2-6 cmH2O',2,6,'cmH2O',null),

('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Infant','Tidal Volume','4-8 mL/kg',4,8,'mL/kg',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Infant','PIP','20-30 cmH2O',20,30,'cmH2O',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Infant','Respiratory Rate','20-30 breaths/min',20,30,'breaths/min',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Infant','FiO2','40-60 %',40,60,'%',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Initial Infant','PEEP','2-4 cmH2O',2,4,'cmH2O',null),

('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Tidal Volume (VT)','5-8 mL/kg',5,8,'mL/kg',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Vital Capacity (VC)','65-75 mL/kg',65,75,'mL/kg',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Respiratory Rate','12-20 breaths/min',12,20,'breaths/min',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Minute Ventilation','5-6 L/min',5,6,'L/min',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','MIP','80 cmH2O',80,80,'cmH2O',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','MEP','160 cmH2O',160,160,'cmH2O',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Static Lung Compliance','60-100 mL/cmH2O',60,100,'mL/cmH2O',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Mean Airway Pressure','5-10 cmH2O',5,10,'cmH2O',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Anatomic Deadspace','1 mL/pound ideal body weight',1,1,'mL/lb',null),
('RTZ Normal Values','2026-02-21','Mechanical Ventilation Typical','Work of Breathing','0.5 ± 0.2 J/L',0.3,0.7,'J/L',null);

commit;
