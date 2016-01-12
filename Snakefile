# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

import pandas as pd

meta_data = pd.read_csv( "metasheet.csv", header = 0 )

print( meta_data.keys() )
