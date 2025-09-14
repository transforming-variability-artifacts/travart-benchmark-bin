import glob
import sys
import numpy as np
import pandas as pd

file_paths = glob.glob("*_results*/" +  "*_" + sys.argv[1] + ".csv")

print(file_paths)

dfs = [pd.read_csv(fp) for fp in file_paths]

all_data = pd.concat(dfs, ignore_index=True)

avg_df = (
    all_data
    .groupby(["fileName", "targetType"], as_index=False)
    .agg(
        targetType = ("targetType", "first"),
        initialSize = ("initialSize", "first"),
        result = ("result", "first"),
        avgDeserializationTime = ("deserializationTime", "mean"),
        avgTransformationTime = ("transformationTime", "mean"),
        complexity = ("complexity", "first")
        )
)

avg_df["avgTransformationTime"] = avg_df["avgTransformationTime"].round(0)
avg_df["avgDeserializationTime"] = avg_df["avgDeserializationTime"].round(0)

avg_df.to_csv("average_transformation_times(" + sys.argv[1] + ").csv", index=False)
