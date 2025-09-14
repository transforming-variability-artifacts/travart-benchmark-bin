import glob
import sys
import numpy as np
import pandas as pd

file_paths = glob.glob(sys.argv[1] + "_results*/" +  "*_" + sys.argv[2] + ".csv")

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

# Do not decimalize avg. time (nanoseconds?)
avg_df["avgTransformationTime"] = avg_df["avgTransformationTime"].round(0)
avg_df["avgDeserializationTime"] = avg_df["avgDeserializationTime"].round(0)

avg_df.to_csv(sys.argv[1] + "_avg_" + sys.argv[2] + ".csv", index=False)
