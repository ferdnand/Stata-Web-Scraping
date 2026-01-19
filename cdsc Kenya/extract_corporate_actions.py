import requests, re
from bs4 import BeautifulSoup
import pandas as pd

page_url='https://www.nse.co.ke/corporate-actions/'
html=requests.get(page_url, timeout=30, headers={'User-Agent':'Mozilla/5.0'}).text
nonce=re.search(r'ajaxnonce"\s*:\s*"([a-f0-9]+)"', html).group(1)
ajaxurl='https://www.nse.co.ke/wp-admin/admin-ajax.php'

sess=requests.Session()
sess.headers.update({'User-Agent':'Mozilla/5.0','Referer':page_url})

def fetch(page):
    data={'page':str(page),'action':'nse_act_grid','security':nonce,'limit':''}
    r=sess.post(ajaxurl, data=data, timeout=30)
    r.raise_for_status()
    return r.text

# discover last page
soup1=BeautifulSoup(fetch(1),'html.parser')
last_id=None
for d in soup1.select('.nse_paginations div'):
    if d.get_text(' ', strip=True).lower()=='last':
        last_id=d.get('id')
last_page=int(last_id) if last_id and last_id.isdigit() else 1

rows=[]
for p in range(1,last_page+1):
    soup=BeautifulSoup(fetch(p),'html.parser')
    for card in soup.select('div.nse_col_3.nse_act'):
        body=card.select_one('div.content_body_nse')
        if not body:
            continue
        company=(body.find('h3').get_text(' ', strip=True) if body.find('h3') else '').strip()
        details=(body.find('p').get_text(' ', strip=True) if body.find('p') else '').strip()
        rows.append({'page':p,'company_name':company,'details_text':details})

# create csv
import csv
filename='nse_corporate_actions.csv'
with open(filename,'w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f, fieldnames=['page','company_name','details_text'])
    w.writeheader()
    w.writerows(rows)

print('rows', len(rows))
print('saved', filename)