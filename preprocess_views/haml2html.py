from urllib.parse import urlencode
from urllib.request import Request, urlopen
from bs4 import BeautifulSoup
import sys

def haml2html(file):
    if not file.endswith('.haml'):
        return
    f = open(file, 'r')
    wf = open(file.replace('html.haml', 'html.erb').replace('haml', 'html.erb'), 'w')
    c = f.read()
    #print(c)
    
    url = 'https://haml2erb.org/' # Set destination URL here
    post_fields = {'haml': c, 'converter': 'herbalizer'}     # Set POST fields here
    
    request = Request(url, urlencode(post_fields).encode())
    json = urlopen(request).read().decode()
    soup = BeautifulSoup(json,"html.parser")
    tag = soup.find(id = 'erb')
    wf.write(tag.string)
    wf.close

def main():
    filename = sys.argv[1]
    haml2html(filename)
    
if __name__ == '__main__':
    main()
