from distutils.core import setup, Extension
 
module1 = Extension('mpu9150', 
		sources = ['mpu9150-python.c',
			   'mpu9150/mpu9150.c', 
			   'mpu9150/quaternion.c', 
			   'mpu9150/vector3d.c',
			   'eMPL/inv_mpu.c',
			   'eMPL/inv_mpu_dmp_motion_driver.c',
		           'glue/linux_glue.c', ], 
		include_dirs=['./mpu9150',
			      './eMPL',
			      './glue'],
		 define_macros=[('EMPL_TARGET_LINUX', None),
                         	('MPU9150', None),
				('AK8975_SECONDARY', None),
				('Wall', None),
				('fsingle-precision-constant', None),
				],
		 libraries=['m'])
 
setup (name = 'PackageName',
        version = '1.0',
        description = 'This is a demo package',
        ext_modules = [module1])
