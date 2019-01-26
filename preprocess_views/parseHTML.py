from bs4 import BeautifulSoup
import re 
from bs4.element import NavigableString

html = "<div class='over'> <%= @over %> <%= @over2 %> <a id = 'link' class ='linka table' href='<% href %>'><%= fds \n outside %></a></div>"
html = open('out', 'r').read()
soup = BeautifulSoup(html, "html.parser")
data = soup.findAll(text=True)

def extractRuby(string):
    index = 0
    outs = []
    shows = []
    show = False
    start = -1
    end = -1
    print("STRING", string)
    for index in range(0, len(string)):
        c1 = string[index]
        if index + 1 < len(string):
            c2 = string[index + 1]
        if index + 2 < len(string):
            c3 = string[index + 2]
        if c1 == '<':
            if c2 == '%':
                if c3 == '=':
                    show = True
                    index += 3
                    start = index
                else:
                    show = False
                    index += 2
                    start = index
            else:
                c1 = c2
                c2 = c3
                index += 1
                if index + 2 < len(string): 
                    c3 = string[index + 2]
        if c1 == '%':
            if c2 == '>':
                end = index
                index += 2
                sentence = string[start: end]
                if sentence.strip().startswith('#') == False:
                    outs.append(sentence)
                    shows.append(show)
                    #print(sentence)
                show = False
                start = -1 
                end = -1
                c1 = c3
                if index + 1 < len(string):
                    c2 = string[index+1] 
                if index + 2 < len(string):
                    c2 = string[index+2] 
            else:
                index += 1
                c1 = c2 
                c2 = c3
                if index + 2 < len(string):
                    c3 = string[index + 2]
    return outs, shows
                    

def visible(element):
    #print "STRING",  str(element.encode('utf-8'))
    if element.parent.name in ['style', 'script', '[document]', 'head', 'title']:
        return False
    elif re.match('<!--.*-->', str(element.encode('utf-8'))):
        return False
    elif re.match('<%=.*%>', str(element.encode('utf-8'))):
        return True
    elif re.match('<%.*%>', str(element.encode('utf-8'))):
        return True
    else:
        return False

cnt = 0
total = 0
def walker(soup):
    global cnt, total
    ks = []
    idf = ''
    if soup.name is not None:
        for child in soup.children:
            #process node
            #print str(child.name) + ":" + str(type(child)) 
            # find the ruby code in child's attributes
            #if type[child] != NavigableString:
            if type(child) != NavigableString:
                attrs = child.attrs
                if child.get('id'):
                    idf = child.get('id')
                    #print('id', idf)
                if child.get('class'):
                    ks = child.get('class')
                    #print('class', ks)
                for a in attrs:
                    extractRuby(attrs[a])
                    
            else:
                out, show = extractRuby(child)
                for o in out:
                    if (child.parent.get('id') or child.parent.get('class')):
                        cnt = cnt + 1
                        #print(child.parent.get('id'), child.parent.get('class'))
                                    
            walker(child)
 
walker(soup)
text = [i for i in soup.recursiveChildGenerator() if type(i) == NavigableString]
#print text
#outs, shows = extractRuby("<%= test %>  <%  test2 %> TEST")
