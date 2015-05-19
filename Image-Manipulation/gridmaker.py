#Gino AC
#Created: 5/19/2015
#Last Modified: 5/19/2015
#Libraries: PIL Libraries: Image and ImageDraw
#Program Description: Creates a grid on an image.

import Image, ImageDraw

imagename = ''

print("Enter name of file to open")
imagename = raw_input()

print("Enter the distance between each gridline (in pixels): ")
lineinterval = int(raw_input())

resultim = imagename[:(len(imagename)-4)] + '_result.png'


image = Image.open(imagename.strip())
draw = ImageDraw.Draw(image)

imsize = image.size

i=0
while i < imsize[0]:
	draw.line([(i,0),(i,imsize[1])])
	i = i + lineinterval

i=0	
while i < imsize[1]:
	draw.line([(0,i),(imsize[0],i)])
	i = i + lineinterval
	
del draw
image.save(resultim)

print("Complete! Image saved as: " + resultim)