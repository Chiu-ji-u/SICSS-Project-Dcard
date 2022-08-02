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
import numpy as np

posts = pd.read_csv('C:/Users/user/Desktop/fresh-post-new(9000).csv')
posts.sort_values(by=['createdAt'], inplace=True, ascending=True)

crawled_cont = pd.read_csv('C:/Users/user/Desktop/fresh-content.csv')
# crawled_cont['id'] = crawled_cont['id'].apply(lambda x: int(x))
crawled_cont.reset_index(drop=True, inplace=True)
crawled_cont.drop_duplicates(subset=['id'], ignore_index=True, inplace=True)
uncrawledID = posts[~posts['id'].isin(crawled_cont['id'])]['id']

# crawled_cont = pd.DataFrame()
driver = webdriver.Chrome("C:/Users/user/Desktop/chromedriver_win32/chromedriver.exe")
for i in uncrawledID:
    try:
        print('postid{}'.format(i))
        # driver = webdriver.Chrome("C:/Users/user/Downloads/chromedriver.exe")
        postid = i
        post_url = 'https://www.dcard.tw/service/api/v2/posts/' + str(postid)
        driver.get(post_url)
        time.sleep(random.uniform(1, 30))
        # print(driver.page_source)
        j2 = driver.find_element(By.TAG_NAME, "body")
        json_resp = json.loads(j2.text)
        x2 = pd.json_normalize(json_resp)
        crawled_cont = pd.concat([crawled_cont, x2], axis=0)
        print(crawled_cont.shape)
        crawled_cont.to_csv(
            'C:/Users/user/Desktop/fresh-content.csv',
            index=False)
    except Exception as e:
        print(e)
        driver.quit()
        driver = webdriver.Chrome("C:/Users/user/Desktop/chromedriver_win32/chromedriver.exe")
        # driver = webdriver.Chrome("C:/Users/user/Downloads/chromedriver.exe",
        #                   chrome_options=chrome_options)


