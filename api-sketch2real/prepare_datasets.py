from os import walk
from PIL import Image


def concat_images(img1, img2):
    newImages = Image.new('RGB', (512, 256), (255, 255, 255))
    newImages.paste(img1, (28, 0))
    newImages.paste(img2, (256+28, 0))
    return newImages


_, _, sketches = next(walk('sketches'))

for index, filename in enumerate(sketches):
    sketch = Image.open('sketches/' + filename)
    photo = Image.open('photos/' + filename)
    concat_images(sketch, photo).save('datasets/' + filename)
    progress = str(int((float(index+1)/len(sketches)) * 100))
    print('DONE : ' + filename +
          '................... [' + progress + '%]')
