import math
import matplotlib.pyplot as plt
import csv

def importXYLog(file_path):
        waypoints_xy = []
        with open(file_path) as xy_csv:
                for line in csv.reader(xy_csv):
                        if len(line) == 2:
                                waypoints_xy.append((float(line[0]), float(line[1])))
        return waypoints_xy

if __name__ == "__main__":
	

	corner_x_pos = []
	corner_y_pos =[]
	
	xy_wp = importXYLog("./xy.log")
	for xy in xy_wp:
		print xy
		corner_x_pos.append(xy[0])
                corner_y_pos.append(xy[1])
	
	plt.plot(corner_x_pos, corner_y_pos, 'k')
        #plt.axis([-15.0, 15.0, 0.0, 30.0])
	plt.show()
	exit()
	

