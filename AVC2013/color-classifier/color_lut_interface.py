#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, ctypes


from PyQt4 import QtGui
from PyQt4 import QtCore

class ColorSpaceView(QtGui.QGraphicsView):
	
	
	def __init__(self, parent):
		super(ColorSpaceView, self).__init__(parent)
		self.pressed = 0
		self.parent_app = parent
		self.planes = []


	def mouseMoveEvent(self, event):
		if self.pressed == 1 and event.buttons() != QtCore.Qt.LeftButton:
			self.pressed = 0
			self.pos_1 = event.pos()
			print 'Area : ', self.pos_0.x(), " -> ", self.pos_1.x()
			start = QtCore.QPointF(self.mapToScene(self.pos_0))
			end = QtCore.QPointF(self.mapToScene(self.pos_1))
			self.scene().addItem(QtGui.QGraphicsRectItem(QtCore.QRectF(start, end)))
			self.planes.append((self.parent_app.getCurrentYVal(), self.pos_0.x(), self.pos_0.y(), self.pos_1.x(), self.pos_1.y()))			
       			print self.planes
	
	def mousePressEvent(self, event):
		if event.button() == QtCore.Qt.LeftButton:
			self.pressed = 1
			self.pos_0 = event.pos()
			print self.pos_0
			
	def getPlanes(self):
		return self.planes

	def drawPlane(self, y_val):
		if len(self.planes) == 2 :
			corner0_eqx = ((self.planes[0][1] - self.planes[1][1])/(self.planes[0][0] - self.planes[1][0]))*(y_val) +  self.planes[0][1];
			corner0_eqy = ((self.planes[0][2] - self.planes[1][2])/(self.planes[0][0] - self.planes[1][0]))*(y_val) +  self.planes[0][2];
			corner1_eqx = ((self.planes[0][3] - self.planes[1][3])/(self.planes[0][0] - self.planes[1][0]))*(y_val) +  self.planes[0][3];
			corner1_eqy = ((self.planes[0][4] - self.planes[1][4])/(self.planes[0][0] - self.planes[1][0]))*(y_val) +  self.planes[0][4];
			width = corner1_eqx- corner0_eqx ;
			height = corner1_eqy- corner0_eqy ;
			if (y_val <= max(self.planes[0][0], self.planes[1][0])) and (y_val >= min(self.planes[0][0], self.planes[1][0])):
				self.scene().addItem(QtGui.QGraphicsRectItem(QtCore.QRectF(corner0_eqx, corner0_eqy, width, height)))

				

class Example(QtGui.QWidget):
    
	def __init__(self):
		super(Example, self).__init__()
		self.initUI()
		self.y_val = 0.0
        
	def initUI(self):      

		self.createImageLut(0)

		self.graphic_view = ColorSpaceView(self)
		self.graphic_view.setGeometry(22, 5, 258, 258)

		self.color_space = QtGui.QGraphicsScene(self.graphic_view)
		self.color_space.setSceneRect(0,0, 256, 256)
		
		self.pix_map = QtGui.QPixmap.fromImage(self.color_lut)
		self.color_space.addPixmap(self.pix_map)	
		self.graphic_view.setScene(self.color_space)
		
		
		self.y_label = QtGui.QLabel("Y=0", self)
		self.y_label.setGeometry(5, 270, 50, 10)


		u_label = QtGui.QLabel("U", self)
		u_label.setGeometry(280, 250, 15, 15)

		v_label = QtGui.QLabel("V", self)
		v_label.setGeometry(5, 5, 15, 15)

		sld = QtGui.QSlider(QtCore.Qt.Horizontal, self)
		sld.setFocusPolicy(QtCore.Qt.NoFocus)
		sld.setGeometry(50, 260, 200, 30)
		sld.valueChanged[int].connect(self.changeValue)
		
		self.gen_button = QtGui.QPushButton("Generate", self)
		self.gen_button.setGeometry(5, 300, 80, 30)
		self.gen_button.clicked.connect(self.generate_lut)

		  # set signals and slots        
		self.graphic_view.setMouseTracking(True)

		self.setGeometry(300, 300, 300, 350)
		self.setWindowTitle('QtGui.QSlider')
		self.show()
        
	def changeValue(self, value):
		self.y_val = round((value/100.0)*255)
		self.y_label.setText("Y="+str(int(round(self.y_val))))
		self.createImageLut(self.y_val)
		self.pix_map = QtGui.QPixmap.fromImage(self.color_lut) 
		self.color_space.addPixmap(self.pix_map)
		self.graphic_view.drawPlane(self.y_val)

	def getCurrentYVal(self):
		return self.y_val

	def generate_lut(self):
		planes = self.graphic_view.getPlanes()
		if len(planes) == 2 :
			f = open('lut_file.lut', 'wb')
			var8 = 0
			acc = 0
			for y in range(0, 16):			
				for v in range(0,16):
					for u in range(0,16):
						y_pos = (y << 4) & 0xF0
						u_pos = (u << 4) & 0xF0
						v_pos = (v << 4) & 0xF0
						corner0_eqx = ((planes[0][1] -planes[1][1])/(planes[0][0] - planes[1][0]))*(y_pos) +  planes[0][1];
						corner0_eqy = ((planes[0][2] - planes[1][2])/(planes[0][0] - planes[1][0]))*(y_pos) +  planes[0][2];
						corner1_eqx = ((planes[0][3] - planes[1][3])/(planes[0][0] - planes[1][0]))*(y_pos) +  planes[0][3];
						corner1_eqy = ((planes[0][4] - planes[1][4])/(planes[0][0] - planes[1][0]))*(y_pos) +  planes[0][4];
						if y_pos >= min(planes[0][0], planes[1][0]) and y_pos <= max(planes[0][0], planes[1][0]):
							if u_pos >= min(corner0_eqx, corner1_eqx) and u_pos <= max(corner0_eqx, corner1_eqx):
								if v_pos >= min(corner0_eqy, corner1_eqy) and v_pos <= max(corner0_eqy, corner1_eqy): 
									var8 |= (1 << 6)
									
													
						if acc == 3:
							f.write(chr(var8))
							print str(hex(var8))						
							#f.write('\n')
							acc = 0
							var8 = 0
						else:
							var8 = var8 >> 2
							acc = acc + 1
			f.close()
		else:
			print 'not enough data'

	def createImageLut(self, pos):
		y = pos	
		self.img_buffer = bytearray(256*256*3)
		for u in range(0,255):
			for v in range(0,255):
				posx = u
				posy = v				
				#y = int(round(y)) & 0xF0 ;
				#u = u & 0xF0 ;
				#v = v & 0xF0 ; 
				r =  y + (1.40 * (v - 128.0))
				g =  y - (0.34 * (u - 128.0)) - (0.71 * (v - 128.0))
				b =  y + (1.77 * (u - 128.0)) 
				r = max(min(int(round(r)), 255), 0)
				g = max(min(int(round(g)), 255), 0)
				b = max(min(int(round(b)), 255), 0)
				self.img_buffer[(posx*(256*3))+(posy*3)] = r
				self.img_buffer[(posx*(256*3))+(posy*3+1)] = g
				self.img_buffer[(posx*(256*3))+(posy*3+2)] = b
		self.color_lut = QtGui.QImage(self.img_buffer, 256, 256,  QtGui.QImage.Format_RGB888)
        	
def main():
    
    app = QtGui.QApplication(sys.argv)
    ex = Example()
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()  
