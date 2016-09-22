# Guided Tutorials

Scripts to run guided tutorials

## Running the scripts

* On Mac OSX, run the command below in a terminal window
```
bash <( curl https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/<tutorial>.sh )
```

* On Windows, open a Command Window as Administrator (Right click 'Run as Administrator') and run the command below
```
@powershell -Command "(new-object net.webclient).DownloadFile('https://raw.githubusercontent.com/PredixDev/guided-tutorials/master/<tutorial>.bat','%TEMP%\<tutorial>.bat')" && "%TEMP%\<tutorial>.bat"
```
