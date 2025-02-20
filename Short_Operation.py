import pandas as pd

DF = pd.read_excel(r'C:\GitRepo\Genrator_Statistics\Data\20240217\Genrator_Statistics_FY2024_Updated.xlsx', engine='openpyxl')
print(DF.head(10))

print (DF.sample(10))

print (DF.tail())

DF.describe

