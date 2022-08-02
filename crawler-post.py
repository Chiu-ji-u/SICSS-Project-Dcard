# -*- coding: utf-8 -*-
"""

@author: hsuwei
"""

import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.by import By
import json
import time
import random
# driver = webdriver.Chrome("C:/Users/user/Downloads/chromedriver.exe")
# url = "https://www.dcard.tw/service/api/v2/forums/freshman/posts?popular=false&limit=100"
# driver.get(url)
# jj = driver.find_element(By.TAG_NAME, "body")
# xxx = pd.json_normalize(json.loads(jj.text))

xxx = pd.read_csv(
    'G:/我的雲端硬碟/分享/SICSS2022_project/raw-data/new/fresh-post9001.csv'
    )

# xxx = xxx[~xxx['id'].isin(old['id'])]
xxx.dropna(subset=['id'], inplace=True)
# xxx['id'] = xxx['id'].astype('str').str.replace('\.0', '')    


driver = webdriver.Chrome("C:/Users/user/Downloads/chromedriver.exe")
for x in range(1, 50):
    try:
        print('爬蟲{}'.format(x))
        # driver = webdriver.Chrome("C:/Users/user/Downloads/chromedriver.exe")
        last_postid = xxx.iloc[-1, 0]
        nxt_url = 'https://www.dcard.tw/service/api/v2/forums/freshman/posts?popular=false&limit=100&before=' + str(last_postid)
        driver.get(nxt_url)
        time.sleep(random.uniform(1, 60))
        # print(driver.page_source)
        j2 = driver.find_element(By.TAG_NAME, "body")
        json_resp = json.loads(j2.text)
        x2 = pd.json_normalize(json_resp)
        xxx = pd.concat([xxx, x2], axis=0)
        print(xxx.shape)
        xxx.to_csv(
            'G:/我的雲端硬碟/分享/SICSS2022_project/raw-data/new/fresh-post9001.csv',
            index=False)
    except Exception as e:
        print(e)
        driver.quit()
        driver = webdriver.Chrome("C:/Users/user/Downloads/chromedriver.exe")






