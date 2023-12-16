# gendermhinequality
Code to replicate the results in "Gender-related self-reported mental health inequalities in primary care in England: Cross-sectional analysis using the GP Patient Survey"

The Stata code replicates the results, figures, and tables of the following paper:
Watkinson, Ruth; Linfield, Aimee; Tielemans, Jack; Francetic, Igor; Munford, Luke, 2023, "Gender-related self-reported mental health inequalities in primary care in England: Cross-sectional analysis using the GP Patient Survey", The Lancet Public Health.

The data uses restricted-access data from the GP Patient Survey for England. Further information about the GPPS and dataset is available at https://gp-patient.co.uk or by contacting gppatientsurvey@ipsos.com. Information relating to the questionnaires is available at https://gp-patient.co.uk/downloads/2023/qandletter/GPPS_2023_Questionnaire_PUBLIC.pdf. The code uses individual-level data from GPPS, which were obtained from Ipsos MORI via an NHS England sharing agreement with our team at the University of Manchester (Reference 199). Further information about the GPPS and dataset is available at https://gp-patient.co.uk or by contacting gppatientsurvey@ipsos.com. The authors of this study cannot share individual-level data as it is the property of NHS England, and managed by Ipsos MORI. Information relating to the questionnaires is available at https://gp-patient.co.uk/downloads/2023/qandletter/GPPS_2023_Questionnaire_PUBLIC.pdf. Researchers can obtain cross-sectional data from 2007 through to 2023 for all available patients by submitting a request to NHS England.

The package includes a folder structure, a stata figure editing routine ("legendonly.grec"), and three do-files, that should be run in the following order:

1 - 20231116_revision2_preparation.do: Prepares the raw data for analysis

2 - 20231116_revision2_descriptives.do: Generates descriptive tables and figures used in the paper

3 - 20231116_revision2_analysis.do: Runs all analyses and generates tables and figures used in the paper


For any questions or feedback, please email the corresponding author. Contact: ruth[dot]watkinson[at]manchester[dot]ac[dot]uk
