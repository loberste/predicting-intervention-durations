# Predictive Analytics of Intervention Durations
This repository contains the code necessary to reproduce the major results of our paper:

**When Every Minute Matters – Using Predictive Analytics of Intervention Durations to Support Hospital Scheduling**  
*[Luis Oberste](https://www.bwl.uni-mannheim.de/heinzl/team/luis-oberste/), [Okan Aydingül](https://www.bwl.uni-mannheim.de/heinzl/team/dr-okan-aydinguel/), [Ekaterina Jussupow](https://www.bwl.uni-mannheim.de/heinzl/team/ekaterina-jussupow/), [Armin Heinzl](https://www.bwl.uni-mannheim.de/heinzl/team/prof-dr-armin-heinzl/)* - University of Mannheim, Germany

[[Paper]](#) [[Conference Homepage]](#)

```
@proceedings{xxx,
...
}
```

## Getting started

### Prerequisites

* MySQL database
* [RapidMiner Studio](https://rapidminer.com)
* [RapidMiner JDBC Connector](https://docs.rapidminer.com/latest/studio/connect/database/jdbc/) for RapidMiner v9.2 and lower


### Dataset

* Since we cannot provide the data due to privacy restrictions, you need to personally acquire the [MIMIC-III dataset](https://mimic.physionet.org/).
* After installing MIMIC-III, additional tables must be generated due to performance reasons (or views, if preferred)
 * Use scripts in the [mysql folder](mysql/) which are adapted from the code provided in the [MIMIC-III code repository](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iii/concepts)
 * In addition, execute [gcs_first_day.sql](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iii/concepts/firstday/gcs_first_day.sql) and store in a `patient_firstday_gcs` table/view

In summary, we use the following data for the experiments:

Source tables|Attributes
-|-
`ADMISSIONS`, `ICUSTAYS`, `PATIENTS`|Admission location, age, current LOS at the hospital, ethnicity, first hospital stay (y/n), gender, insurance, language, length of current hospital stay so far, marital status, no. of previous hospital stays, no. of previous ICU stays, religion, time of admission to the hospital, time of admission to the ICU
`CHARTEVENTS`, `INPUTEVENTS_MV`|Weight
`CHARTEVENTS`|Mean measurements on the first day: arterial pressure, blood glucose level, body temperature, diastolic blood pressure, heart rate, respiratory rate, saturation of peripheral oxygen (SpO2), systolic blood pressure
`DIAGNOSES_ICD`, `PROCEDURES_ICD`|No. of diagnoses, no. of procedures, primary diagnosis, primary procedure, secondary diagnosis, secondary procedure
`TRANSFERS`|Speciality patients were admitted to
`INPUTEVENTS_MV`|Duration of octreotide intake, no. of previous octreotide intakes, start time
`CHARTEVENTS`|qSOFA
`CHARTEVENTS`, `CPTEVENTS`|Comorbidities: alcohol abuse, cardiac arrhythmias, chronic pulmonary, coagulopathy, fluid electrolyte disorder, liver disease, uncomplicated diabetes, weight loss


<br>

## Running the code

* Download the `predicting-intervention-durations.zip` file from the [rapidminer folder](rapidminer/) and extract the content locally (the root folder contains `data/`, `training/`, `fine-tuning/` and `_metadata.xml`)
* In RapidMiner, create a local repository, not using the standard location but selecting the unzipped folder as the root directory

Now, you should see the two folders in your RapidMiner repository overview. The following tables show how to *chronologically* use the scripts for both data extraction and model learning within the RapidMiner software.

### Data

In your local repository, you need to create a `connection` to the MIMIC-III database. Name the connection `MIMIC` for automatic recognition of the connection in the provided processes.

Process|Input|Important steps|Output
-|-|-|-
`additional-data-query`|(SQL statements)|performs all subprocesses of the `additional/` directory to extract patient- and admission-related data|dataset (without target label)
`duration-query`|(SQL statements)|performs extraction of fluid intake durations by considering |fluid intake durations (target label)
`duration-selection`|(all above)|joins fluid intake durations with all patient- and admission-related data|selected data
`preprocessing`|selected data|data cleaning, date feature engineering|preprocessed data

Further details on the data processing can be found in our paper.

<br>

### Training

#### Algorithm comparison

As described in the paper, we used the following RapidMiner machine learning implementations to train models:

* Feed-forward artificial neural network (ANN)
* Deep learning (DL)
* Generalized linear model (GLM)
* Gradient-boosted tree (GBT)
* Linear regression (LR)
* Random forest (RF)
* Support vector machine (SVM)

Process|Input|Important steps|Output
-|-|-|-
`training-nested-CV`|preprocessed data|nested k-fold cross-validation with attribute encoding, normalization, and missing value handling (if appropriate)|for each model, stores the model itself, its final performance, best parameters, as well as attribute weights (where possible) in the corresponding `training/results/[model]` folder

#### Model fine-tuning

For the best performing models (GBT and LR), additional fine-tuning was performed:

Step|Process|Input|Important steps|Output
-|-|-|-|-
1.|`two-best`|(as in training)|k-fold cross-validation with forward selection for GBT and LR|(as in training)
2.|`GBT-best`|(as in training)|k-fold cross-validation for GBT|(as in training)
