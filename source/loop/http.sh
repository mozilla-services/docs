#! /bin/bash
http GET localhost:5000 --verbose
http --session loop POST localhost:5000/registration simple_push_url=https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyuverbo --verbose
http --session loop POST localhost:5000/call-url callerId=alexis --verbose
http GET localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJPGCK3LKt6yF3KDUFTXKRf_qxgfOW_eSKhJsvmyO29ugMq0TsZ3tpwODlnNSag5zymhAg80atS2ivw2GgZCHgvQS7KrkmvO68lnS1jb-v70x2yILSh4S9Z9XuZnQgNbAgME --verbose
http POST localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJPGCK3LKt6yF3KDUFTXKRf_qxgfOW_eSKhJsvmyO29ugMq0TsZ3tpwODlnNSag5zymhAg80atS2ivw2GgZCHgvQS7KrkmvO68lnS1jb-v70x2yILSh4S9Z9XuZnQgNbAgME --verbose
http --session=loop GET localhost:5000/calls\?version=0 --verbose
http GET localhost:5000/calls/id/1afeb4340d995938248ce7b3e953fe80 --verbose
http --session=loop DELETE localhost:5000/calls/id/1afeb4340d995938248ce7b3e953fe80 --verbose
http --session=loop DELETE localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJPGCK3LKt6yF3KDUFTXKRf_qxgfOW_eSKhJsvmyO29ugMq0TsZ3tpwODlnNSag5zymhAg80atS2ivw2GgZCHgvQS7KrkmvO68lnS1jb-v70x2yILSh4S9Z9XuZnQgNbAgME --verbose
