// TTC infarct measurement with guided manual polygon ROIs.
// One photo contains multiple coronal slices. The user traces each ROI;
// the macro records, validates, calculates, and exports the measurements.

if (getArgument()=="self-test") {
    runSelfTest();
} else if (getArgument()=="roi-self-test") {
    runRoiRecoverySelfTest();
} else {
    runSession();
}

function runSession() {
    continueSession=1;
    while (continueSession==1) {
        runInteractive();

        goNext=getBoolean(
            fromCharCode(24403,21069,21160,29289,30340,27979,37327,19982,20445,23384,24050,32463,23436,25104,12290)+"\n\n"+
            "Yes = Next animal\n"+
            "No = Finish");

        if (goNext==1)
            continueSession=openNextAnimal();
        else
            continueSession=0;
    }
    showStatus("TTC"+fromCharCode(27979,37327,65306,26412,27425,20998,26512,24050,32467,26463));
}

function openNextAnimal() {
    previousImageCount=nImages;
    run("Open...");
    if (nImages<=previousImageCount) {
        showMessage(fromCharCode(26410,25171,24320,19979,19968,24352,29031,29255),
            fromCharCode(27809,26377,26816,27979,21040,26032,30340,29031,29255,65292,19978,19968,21482,21160,29289,30340,32467,26524,20173,28982,20445,30041,12290)+"\n"+fromCharCode(26412,27425,20998,26512,32467,26463,12290));
        return 0;
    }

    nextImageTitle=getTitle();
    run("Clear Results");
    roiManager("reset");
    selectWindow(nextImageTitle);
    showStatus("TTC"+fromCharCode(27979,37327,65306,24050,25171,24320,19979,19968,21482,21160,29289,30340,29031,29255));
    return 1;
}

function runInteractive() {
    if (nImages==0) {
        if (nResults>0 || roiManager("count")>0)
            showMessage(fromCharCode(37325,26032,36873,25321,21407,29031,29255),
                fromCharCode(26816,27979,21040,26410,23436,25104,30340,27979,37327,35760,24405,65292,20294,21407,29031,29255,31383,21475,24050,32463,20851,38381,12290)+"\n"+
                fromCharCode(28857,20987,30830,23450,21518,65292,35831,37325,26032,25171,24320,26412,27425,20013,26029,26102,20351,29992,30340,21516,19968,24352,21160,29289,29031,29255,12290)+"\n"+
                fromCharCode(19981,35201,36873,25321,19979,19968,21482,21160,29289,30340,29031,29255,65292,21542,21017,24050,26377,36873,21306,20250,19982,22270,20687,19981,21305,37197,12290));
        run("Open...");
        if (nImages==0)
            exit(fromCharCode(26410,25171,24320,22270,20687,65292,20998,26512,24050,21462,28040,12290));
    }

    sourceTitle = getTitle();
    getPixelSize(unit, pixelWidth, pixelHeight, voxelDepth);
    showMessage(fromCharCode(35774,32622,26412,21482,21160,29289,30340,27604,20363,23610),
        fromCharCode(27599,21482,21160,29289,22343,38656,21333,29420,26631,23450,12290,35831,22312,24403,21069,29031,29255,30340,26631,23610,19978,30011,19968,26465,30452,32447,12290)+"\n"+
        fromCharCode(25512,33616,36830,25509,30456,37051,20004,26465,21400,31859,20027,21051,24230,32447,65292,21363,23454,38469,36317,31163)+"10 mm"+fromCharCode(12290)+"\n"+
        fromCharCode(30011,22909,21518,28857,20987,19979,19968,31383,21475,30340,30830,23450,25353,38062,12290));
    setTool("line");
    waitForUser(fromCharCode(26412,21482,21160,29289,30340,27604,20363,23610), fromCharCode(30011,22909,26631,23610,32447,21518,28857,20987,30830,23450,12290));
    if (selectionType()!=5)
        exit(fromCharCode(27809,26377,26816,27979,21040,30452,32447,36873,21306,65292,35831,37325,26032,36816,34892,33050,26412,24182,20808,30011,26631,23610,32447,12290));
    run("Set Scale...", "known=10 unit=mm");
    getPixelSize(unit, pixelWidth, pixelHeight, voxelDepth);

    existingRois=roiManager("count");
    resumeCount=countRecoverableSlices();
    canResume=0;
    if (resumeCount>0) canResume=1;
    defaultSliceCount=5;
    if (resumeCount>=defaultSliceCount) defaultSliceCount=resumeCount+1;
    defaultThickness=2;
    defaultAnimal=File.getNameWithoutExtension(sourceTitle);

    Dialog.create("TTC Analysis Settings");
    Dialog.addString("Animal ID", defaultAnimal);
    Dialog.addNumber("Number of slices", defaultSliceCount, 0, 3, "slices");
    Dialog.addNumber("Slice thickness", defaultThickness, 2, 3, "mm");
    if (canResume==1) {
        Dialog.addCheckbox("Recalculate Results from ROI Manager", 1);
        Dialog.addMessage("Recoverable completed slices: "+resumeCount+".\n"+
            "Results will be rebuilt from the saved ROIs before continuing.");
    }
    Dialog.addMessage(fromCharCode(27599,29255,20381,27425,22280,36873,65306,20581,20391,25972,20010,21322,29699,12289,24739,20391,25972,20010,21322,29699,12289,24739,20391,26775,27515,21306,22495,12290)+"\n"+fromCharCode(26775,27515,21306,21487,30041,31354,65292,34920,31034,35813,29255,26775,27515,38754,31215,20026)+"0"+fromCharCode(12290));
    Dialog.show();
    animalID = sanitize(Dialog.getString());
    sliceCount = round(Dialog.getNumber());
    thickness = Dialog.getNumber();
    resumeExisting=0;
    if (canResume==1) resumeExisting=Dialog.getCheckbox();
    if (animalID=="") animalID="TTC_sample";
    if (sliceCount<1) exit(fromCharCode(33041,29255,25968,37327,24517,39035,22823,20110)+"0"+fromCharCode(12290));
    if (thickness<=0) exit(fromCharCode(33041,29255,21402,24230,24517,39035,22823,20110)+"0"+fromCharCode(12290));
    if (resumeExisting==1 && sliceCount<resumeCount)
        exit(fromCharCode(29031,29255,20869,33041,29255,24635,25968,19981,33021,23567,20110,24050,23436,25104,30340)+" "+resumeCount+" "+fromCharCode(29255,12290));

    run("Set Measurements...", "area decimal=3");
    totalContra=0;
    totalIpsi=0;
    totalRaw=0;
    totalCorrected=0;
    startSlice=1;

    if (resumeExisting==1) {
        lastRecoveredRoi=lastRoiIndexForSlices(resumeCount);
        deleteRoisFrom(lastRecoveredRoi+1);
        rebuildResultsFromRois(sourceTitle, animalID, thickness, resumeCount);
        for (row=0; row<resumeCount; row++) {
            totalContra=totalContra+getResult("Contralateral_mm2", row);
            totalIpsi=totalIpsi+getResult("Ipsilateral_mm2", row);
            totalRaw=totalRaw+getResult("Raw_Infarct_mm2", row);
            totalCorrected=totalCorrected+getResult("Corrected_Infarct_mm2", row);
        }
        startSlice=resumeCount+1;
        roiManager("Show All without labels");
        selectWindow(sourceTitle);
        if (startSlice<=sliceCount)
            showMessage("Results Recalculated",
                "Results for the first "+resumeCount+" slices were rebuilt from ROI Manager.\n"+
                "Continue with slice "+startSlice+".");
        else
            showMessage("Results Recalculated",
                "All "+resumeCount+" slices were rebuilt from ROI Manager.\n"+
                "Continue to summary and saving.");
    } else {
        run("Clear Results");
        roiManager("reset");
    }

    for (slice=startSlice; slice<=sliceCount; slice++) {
        showStatus("TTC"+fromCharCode(27979,37327,65306,20934,22791,31532)+" "+slice+" / "+sliceCount+" "+fromCharCode(29255));
        showProgress(slice-1, sliceCount);
        accepted=0;
        while (accepted==0) {
            roiStart=roiManager("count");
            selectWindow(sourceTitle);
            contra=requiredAreaROI(sourceTitle, slice, sliceCount,
                fromCharCode(20581,20391,25972,20010,21322,29699),
                fromCharCode(22280,20986,20581,20391,25972,20010,21322,29699,65292,27839,20013,32447,21644,22806,32536,38381,21512,12290),
                "S"+pad2(slice)+"_Contralateral");

            selectWindow(sourceTitle);
            ipsi=requiredAreaROI(sourceTitle, slice, sliceCount,
                fromCharCode(24739,20391,25972,20010,21322,29699),
                fromCharCode(22280,20986,24739,20391,25972,20010,21322,29699,65292,27839,21516,19968,26465,20013,32447,21644,22806,32536,38381,21512,12290),
                "S"+pad2(slice)+"_Ipsilateral");

            selectWindow(sourceTitle);
            raw=optionalAreaROI(sourceTitle, slice, sliceCount,
                fromCharCode(24739,20391,26775,27515,21306,22495),
                fromCharCode(20165,22280,20986,24739,20391,20869,32905,30524,21028,23450,30340)+"TTC"+fromCharCode(26410,26579,33394,26775,27515,21306,12290)+"\n"+
                fromCharCode(27491,24120,27973,33394,32467,26500,12289,33041,23460,12289,35010,38553,21644,21453,20809,19981,35201,32435,20837,12290)+"\n"+
                fromCharCode(33509,35813,29255,26080,26775,27515,21306,65292,35831,19981,30011,36873,21306,30452,25509,28857,20987,30830,23450,12290),
                "S"+pad2(slice)+"_Infarct");

            corrected=correctedArea(contra, ipsi, raw);
            correctedPercent=100*corrected/contra;
            warning="";
            acceptByDefault=1;
            if (raw>ipsi) {
                warning="\n"+fromCharCode(35686,21578,65306,26775,27515,38754,31215,22823,20110,24739,20391,38754,31215,65292,35831,37325,30011,12290);
                acceptByDefault=0;
            }
            if (corrected>contra*1.05) {
                warning=warning+"\n"+fromCharCode(35686,21578,65306,26657,27491,26775,27515,38754,31215,24322,24120,20559,22823,65292,35831,26816,26597,19977,20010,36873,21306,12290);
                acceptByDefault=0;
            }

            Dialog.create("Confirm Slice "+slice);
            Dialog.addMessage(
                fromCharCode(20581,20391,38754,31215,65306)+d2s(contra,3)+" "+unit+"^2\n"+
                fromCharCode(24739,20391,38754,31215,65306)+d2s(ipsi,3)+" "+unit+"^2\n"+
                fromCharCode(21407,22987,26775,27515,38754,31215,65306)+d2s(raw,3)+" "+unit+"^2\n"+
                fromCharCode(26657,27491,26775,27515,38754,31215,65306)+d2s(corrected,3)+" "+unit+"^2\n"+
                fromCharCode(26657,27491,26775,27515,29575,65306)+d2s(correctedPercent,2)+" %"+warning);
            Dialog.addCheckbox("Accept this slice result", acceptByDefault);
            Dialog.show();
            accepted=Dialog.getCheckbox();
            if (accepted==0)
                deleteRoisFrom(roiStart);
        }

        totalContra=totalContra+contra;
        totalIpsi=totalIpsi+ipsi;
        totalRaw=totalRaw+raw;
        totalCorrected=totalCorrected+corrected;
        appendResult(animalID, slice, thickness, contra, ipsi, raw, corrected);
        showProgress(slice, sliceCount);
        if (slice<sliceCount) {
            selectWindow(sourceTitle);
            showStatus("TTC"+fromCharCode(27979,37327,65306,31532)+" "+slice+" "+fromCharCode(29255,24050,23436,25104,65292,25509,19979,26469,31532)+" "+(slice+1)+" "+fromCharCode(29255));
            wait(200);
        }
    }

    totalPercent=100*totalCorrected/totalContra;
    totalVolume=totalCorrected*thickness;
    appendTotal(animalID, thickness, totalContra, totalIpsi, totalRaw, totalCorrected);
    updateResults();

    selectWindow(sourceTitle);
    showMessage(fromCharCode(36873,21306,27493,39588,23436,25104),
        fromCharCode(24050,23436,25104)+" "+sliceCount+" "+fromCharCode(29255,33041,29255,30340,36873,21306,21644,35745,31639,12290)+"\n\n"+
        fromCharCode(28857,20987,30830,23450,21518,65292,35831,36873,25321,32467,26524,20445,23384,25991,20214,22841,12290));
    saveDir=getDirectory(fromCharCode(36873,25321,32467,26524,20445,23384,25991,20214,22841));
    excelStatus="\nExcel"+fromCharCode(34920,65306,26410,20445,23384);
    if (saveDir!="") {
        base=saveDir+animalID+"_TTC_polygon";
        csvPath=base+"_results.csv";
        xlsxPath=base+"_results.xlsx";
        saveFormattedCSV(csvPath, animalID, sliceCount, thickness,
            totalContra, totalIpsi, totalRaw, totalCorrected);
        excelResult=createFormattedExcel(csvPath, xlsxPath);
        excelErrorPath=base+"_excel_error.txt";
        if (File.exists(xlsxPath)) {
            excelStatus="\nExcel"+fromCharCode(34920,65306,24050,29983,25104);
            if (File.exists(excelErrorPath)) File.delete(excelErrorPath);
        } else {
            File.saveString(excelResult, excelErrorPath);
            excelStatus="\nExcel: failed; details saved in _excel_error.txt";
        }
        if (roiManager("count")>0)
            roiManager("Save", base+"_ROIs.zip");
        saveOverlay(sourceTitle, base+"_overlay.png");
    }

    selectWindow(sourceTitle);
    showMessage("TTC"+fromCharCode(20998,26512,23436,25104),
        fromCharCode(21160,29289,32534,21495,65306)+animalID+"\n"+
        fromCharCode(33041,29255,25968,37327,65306)+sliceCount+"\n\n"+
        fromCharCode(20581,20391,24635,38754,31215,65306)+d2s(totalContra,3)+" "+unit+"^2\n"+
        fromCharCode(24739,20391,24635,38754,31215,65306)+d2s(totalIpsi,3)+" "+unit+"^2\n"+
        fromCharCode(21407,22987,26775,27515,24635,38754,31215,65306)+d2s(totalRaw,3)+" "+unit+"^2\n"+
        fromCharCode(26657,27491,26775,27515,24635,38754,31215,65306)+d2s(totalCorrected,3)+" "+unit+"^2\n"+
        fromCharCode(26657,27491,26775,27515,20307,31215,65306)+d2s(totalVolume,3)+" mm^3\n"+
        fromCharCode(24635,20307,26657,27491,26775,27515,29575,65306)+d2s(totalPercent,2)+" %"+excelStatus);
}

function requiredAreaROI(sourceTitle, slice, sliceCount, role, instruction, roiName) {
    valid=0;
    while (valid==0) {
        selectWindow(sourceTitle);
        showStatus("TTC"+fromCharCode(27979,37327,65306,31532)+" "+slice+" / "+sliceCount+" "+fromCharCode(29255)+" - "+role);
        run("Select None");
        setTool("polygon");
        waitForUser(fromCharCode(31532)+" "+slice+" / "+sliceCount+" "+fromCharCode(29255,65306)+role,
            instruction+"\n\n"+
            fromCharCode(21333,20987,20381,27425,28155,21152,33410,28857,65292,21452,20987,38381,21512,12290)+"\n"+
            fromCharCode(21487,25302,21160,33410,28857,35843,25972,65292,30830,35748,21518,28857,20987,30830,23450,12290));
        type=selectionType();
        valid=isAreaSelection(type);
        if (valid==0)
            showMessage(fromCharCode(36873,21306,26080,25928), fromCharCode(35831,20351,29992,22810,36793,24418,25110,25163,32472,36873,21306,22280,20986,19968,20010,38381,21512,38754,31215,21306,22495,12290));
    }
    getStatistics(area);
    roiManager("Add");
    index=roiManager("count")-1;
    roiManager("Select", index);
    roiManager("Rename", roiName);
    roiManager("Show All without labels");
    selectWindow(sourceTitle);
    return area;
}

function optionalAreaROI(sourceTitle, slice, sliceCount, role, instruction, roiName) {
    valid=0;
    while (valid==0) {
        selectWindow(sourceTitle);
        showStatus("TTC"+fromCharCode(27979,37327,65306,31532)+" "+slice+" / "+sliceCount+" "+fromCharCode(29255)+" - "+role);
        run("Select None");
        setTool("polygon");
        waitForUser(fromCharCode(31532)+" "+slice+" / "+sliceCount+" "+fromCharCode(29255,65306)+role,
            instruction+"\n\n"+
            fromCharCode(26377,26775,27515,65306,21333,20987,28155,21152,33410,28857,65292,21452,20987,38381,21512,21518,28857,20987,30830,23450,12290)+"\n"+
            fromCharCode(26080,26775,27515,65306,20445,25345,26080,36873,21306,65292,30452,25509,28857,20987,30830,23450,12290));
        type=selectionType();
        if (type==-1) {
            markZeroInfarct(slice);
            return 0;
        }
        valid=isAreaSelection(type);
        if (valid==0)
            showMessage(fromCharCode(36873,21306,26080,25928), fromCharCode(26775,27515,21306,24517,39035,26159,38381,21512,38754,31215,36873,21306,65307,35831,37325,26032,22280,36873,65292,25110,28165,38500,36873,21306,34920,31034)+"0"+fromCharCode(12290));
    }
    getStatistics(area);
    roiManager("Add");
    index=roiManager("count")-1;
    roiManager("Select", index);
    roiManager("Rename", roiName);
    roiManager("Show All without labels");
    selectWindow(sourceTitle);
    return area;
}

function isAreaSelection(type) {
    return type==0 || type==1 || type==2 || type==3 || type==4 || type==9;
}

function markZeroInfarct(slice) {
    regularName="S"+pad2(slice)+"_Ipsilateral";
    index=findRoiIndexByName(regularName);
    if (index>=0) {
        roiManager("Select", index);
        roiManager("Rename", regularName+"_ZERO");
    }
}

function findRoiIndexByName(targetName) {
    count=roiManager("count");
    for (findIndex=0; findIndex<count; findIndex++) {
        currentName=RoiManager.getName(findIndex);
        if (currentName==targetName) return findIndex;
    }
    return -1;
}

function findIpsiRoiIndex(slice) {
    regularIndex=findRoiIndexByName("S"+pad2(slice)+"_Ipsilateral");
    if (regularIndex>=0) return regularIndex;
    return findRoiIndexByName("S"+pad2(slice)+"_Ipsilateral_ZERO");
}

function hasAnyRoiForSlice(slice) {
    prefix="S"+pad2(slice)+"_";
    count=roiManager("count");
    for (scanIndex=0; scanIndex<count; scanIndex++) {
        currentName=RoiManager.getName(scanIndex);
        if (startsWith(currentName, prefix)) return 1;
    }
    return 0;
}

function countRecoverableSlices() {
    recovered=0;
    recoverySlice=1;
    while (recoverySlice<=999) {
        contraIndex=findRoiIndexByName("S"+pad2(recoverySlice)+"_Contralateral");
        ipsiIndex=findIpsiRoiIndex(recoverySlice);
        infarctIndex=findRoiIndexByName("S"+pad2(recoverySlice)+"_Infarct");
        zeroIndex=findRoiIndexByName("S"+pad2(recoverySlice)+"_Ipsilateral_ZERO");
        if (contraIndex<0 || ipsiIndex<0) return recovered;
        if (infarctIndex<0 && zeroIndex<0 && hasAnyRoiForSlice(recoverySlice+1)==0)
            return recovered;
        recovered=recoverySlice;
        recoverySlice=recoverySlice+1;
    }
    return recovered;
}

function lastRoiIndexForSlices(completedSlices) {
    lastIndex=-1;
    for (recoverySlice=1; recoverySlice<=completedSlices; recoverySlice++) {
        index=findRoiIndexByName("S"+pad2(recoverySlice)+"_Contralateral");
        if (index>lastIndex) lastIndex=index;
        index=findIpsiRoiIndex(recoverySlice);
        if (index>lastIndex) lastIndex=index;
        index=findRoiIndexByName("S"+pad2(recoverySlice)+"_Infarct");
        if (index>lastIndex) lastIndex=index;
    }
    return lastIndex;
}

function measureRoiAt(sourceTitle, index) {
    selectWindow(sourceTitle);
    roiManager("Select", index);
    getStatistics(area);
    return area;
}

function rebuildResultsFromRois(sourceTitle, animalID, thickness, completedSlices) {
    run("Clear Results");
    for (recoverySlice=1; recoverySlice<=completedSlices; recoverySlice++) {
        contraIndex=findRoiIndexByName("S"+pad2(recoverySlice)+"_Contralateral");
        ipsiIndex=findIpsiRoiIndex(recoverySlice);
        infarctIndex=findRoiIndexByName("S"+pad2(recoverySlice)+"_Infarct");
        contra=measureRoiAt(sourceTitle, contraIndex);
        ipsi=measureRoiAt(sourceTitle, ipsiIndex);
        raw=0;
        if (infarctIndex>=0) raw=measureRoiAt(sourceTitle, infarctIndex);
        corrected=correctedArea(contra, ipsi, raw);
        appendResult(animalID, recoverySlice, thickness, contra, ipsi, raw, corrected);
    }
    selectWindow(sourceTitle);
}

function correctedArea(contra, ipsi, raw) {
    value=contra-ipsi+raw;
    if (value<0) value=0;
    return value;
}

function appendResult(animalID, slice, thickness, contra, ipsi, raw, corrected) {
    row=nResults;
    setResult("Animal", row, animalID);
    setResult("Slice", row, slice);
    setResult("Thickness_mm", row, thickness);
    setResult("Contralateral_mm2", row, contra);
    setResult("Ipsilateral_mm2", row, ipsi);
    setResult("Raw_Infarct_mm2", row, raw);
    setResult("Corrected_Infarct_mm2", row, corrected);
    setResult("Corrected_Percent", row, 100*corrected/contra);
    setResult("Corrected_Volume_mm3", row, corrected*thickness);
    updateResults();
}

function appendTotal(animalID, thickness, contra, ipsi, raw, corrected) {
    row=nResults;
    setResult("Animal", row, animalID);
    setResult("Slice", row, "TOTAL");
    setResult("Thickness_mm", row, thickness);
    setResult("Contralateral_mm2", row, contra);
    setResult("Ipsilateral_mm2", row, ipsi);
    setResult("Raw_Infarct_mm2", row, raw);
    setResult("Corrected_Infarct_mm2", row, corrected);
    setResult("Corrected_Percent", row, 100*corrected/contra);
    setResult("Corrected_Volume_mm3", row, corrected*thickness);
}

function saveFormattedCSV(outputPath, animalID, sliceCount, thickness,
    totalContra, totalIpsi, totalRaw, totalCorrected) {
    squared=fromCharCode(178);
    cubed=fromCharCode(179);
    csv=fromCharCode(65279)+
        "Record,Animal,Slice,Thickness (mm),"+
        "Contralateral area (mm"+squared+"),"+
        "Ipsilateral area (mm"+squared+"),"+
        "Raw infarct area (mm"+squared+"),"+
        "Corrected infarct area (mm"+squared+"),"+
        "Corrected infarct (%),"+
        "Corrected volume (mm"+cubed+")\n";

    for (row=0; row<sliceCount; row++) {
        contra=getResult("Contralateral_mm2", row);
        ipsi=getResult("Ipsilateral_mm2", row);
        raw=getResult("Raw_Infarct_mm2", row);
        corrected=getResult("Corrected_Infarct_mm2", row);
        percent=100*corrected/contra;
        volume=corrected*thickness;
        csv=csv+(row+1)+","+animalID+","+(row+1)+","+
            d2s(thickness,1)+","+d2s(contra,3)+","+d2s(ipsi,3)+","+
            d2s(raw,3)+","+d2s(corrected,3)+","+d2s(percent,3)+","+
            d2s(volume,3)+"\n";
    }

    totalPercent=100*totalCorrected/totalContra;
    totalVolume=totalCorrected*thickness;
    csv=csv+(sliceCount+1)+","+animalID+",TOTAL,"+
        d2s(thickness,1)+","+d2s(totalContra,3)+","+d2s(totalIpsi,3)+","+
        d2s(totalRaw,3)+","+d2s(totalCorrected,3)+","+
        d2s(totalPercent,3)+","+d2s(totalVolume,3)+"\n";
    File.saveString(csv, outputPath);
}

function findFormatterPath() {
    macroPath=getInfo("macro.filepath");
    if (macroPath!="") {
        candidate=File.getDirectory(macroPath)+"format_ttc_results.py";
        if (File.exists(candidate)) return candidate;
    }

    toolFolder="TTC_ImageJ_"+fromCharCode(22810,36793,24418,21322,33258,21160,27979,37327);
    imageJDir=getDirectory("imagej");
    parentDir=imageJDir+"../";
    candidate=parentDir+toolFolder+"/format_ttc_results.py";
    if (File.exists(candidate)) return candidate;
    // The toolkit directory may include a version suffix such as V0.9.0.
    siblings=getFileList(parentDir);
    for (folder=0; folder<siblings.length; folder++) {
        if (indexOf(siblings[folder], toolFolder)==0) {
            candidate=parentDir+siblings[folder]+"format_ttc_results.py";
            if (File.exists(candidate)) return candidate;
        }
    }

    currentDir=getDirectory("current");
    candidate=currentDir+"format_ttc_results.py";
    if (File.exists(candidate)) return candidate;
    candidate=currentDir+toolFolder+"/format_ttc_results.py";
    if (File.exists(candidate)) return candidate;
    candidate=currentDir+"../"+toolFolder+"/format_ttc_results.py";
    if (File.exists(candidate)) return candidate;
    return "";
}

function createFormattedExcel(csvPath, xlsxPath) {
    formatterPath=findFormatterPath();
    if (formatterPath=="")
        return "ERROR: format_ttc_results.py was not found";

    if (File.exists(xlsxPath)) {
        File.delete(xlsxPath);
        if (File.exists(xlsxPath))
            return "ERROR: existing XLSX is open or cannot be overwritten: "+xlsxPath;
    }

    pythonPath="F:\\Anaconda\\python.exe";
    if (File.exists(pythonPath))
        result=exec(pythonPath, formatterPath, csvPath, xlsxPath);
    else
        result=exec("python", formatterPath, csvPath, xlsxPath);

    if (File.exists(xlsxPath)) return "OK: "+xlsxPath+"\n"+result;
    return "ERROR: Python did not create the XLSX file.\n"+result;
}

function deleteRoisFrom(first) {
    for (i=roiManager("count")-1; i>=first; i--) {
        roiManager("Select", i);
        roiManager("Delete");
    }
    run("Select None");
}

function saveOverlay(sourceTitle, outputPath) {
    selectWindow(sourceTitle);
    run("Duplicate...", "title=TTC_ROI_Overlay");
    roiManager("Show All without labels");
    run("Flatten");
    saveAs("PNG", outputPath);
    close();
    roiManager("Show None");
    selectWindow(sourceTitle);
}

function pad2(value) {
    if (value<10) return "0"+value;
    return ""+value;
}

function sanitize(text) {
    text=replace(text, "\\", "_");
    text=replace(text, "/", "_");
    text=replace(text, ":", "_");
    text=replace(text, "*", "_");
    text=replace(text, "?", "_");
    text=replace(text, "\"", "_");
    text=replace(text, "<", "_");
    text=replace(text, ">", "_");
    text=replace(text, "|", "_");
    text=replace(text, ",", "_");
    return text;
}

function runSelfTest() {
    tolerance=0.000001;
    fail=0;
    if (fromCharCode(20013,25991)!=fromCharCode(20013)+fromCharCode(25991)) fail=fail+1;
    if (abs(correctedArea(44.207,43.347,1.779)-2.639)>tolerance) fail=fail+1;
    if (correctedArea(63.667,70.955,0)!=0) fail=fail+1;
    if (abs(correctedArea(55.006,54.739,14.891)-15.158)>tolerance) fail=fail+1;
    safeName=sanitize("A/B:C");
    sliceLabel=pad2(5);
    if (safeName!="A_B_C") fail=fail+1;
    if (sliceLabel!="05") fail=fail+1;

    setResult("Contralateral_mm2", 0, 51.207);
    setResult("Ipsilateral_mm2", 0, 46.967);
    setResult("Raw_Infarct_mm2", 0, 27.579);
    setResult("Corrected_Infarct_mm2", 0, 31.818);
    testPath=getDirectory("temp")+"TTC_Polygon_CSV_SelfTest.csv";
    saveFormattedCSV(testPath, "2803", 1, 2,
        51.207, 46.967, 27.579, 31.818);
    csvText=File.openAsString(testPath);
    if (indexOf(csvText, "Record,Animal,Slice,Thickness (mm)")<0) fail=fail+1;
    if (indexOf(csvText, "1,2803,1,2.0,51.207,46.967,27.579,31.818,62.136,63.636")<0)
        fail=fail+1;
    if (indexOf(csvText, "2,2803,TOTAL,2.0,51.207,46.967,27.579,31.818,62.136,63.636")<0)
        fail=fail+1;
    xlsxTestPath=getDirectory("temp")+"TTC_Polygon_XLSX_SelfTest.xlsx";
    excelTestResult=createFormattedExcel(testPath, xlsxTestPath);
    if (startsWith(excelTestResult, "OK")==0) fail=fail+1;
    if (File.exists(xlsxTestPath)==0) fail=fail+1;
    File.delete(testPath);
    File.delete(xlsxTestPath);
    if (fail>0) exit("SELF_TEST_FAILED: "+fail);
    print("SELF_TEST_OK");
}

function addRecoveryTestRoi(name, x, y, width, height) {
    makeRectangle(x, y, width, height);
    roiManager("Add");
    index=roiManager("count")-1;
    roiManager("Select", index);
    roiManager("Rename", name);
}

function runRoiRecoverySelfTest() {
    fail=0;
    newImage("TTC_ROI_RECOVERY_TEST", "8-bit black", 100, 100, 1);
    sourceTitle=getTitle();
    roiManager("reset");
    if (nResults>0) run("Clear Results");

    addRecoveryTestRoi("S01_Contralateral", 0, 0, 10, 10);
    addRecoveryTestRoi("S01_Ipsilateral", 20, 0, 9, 10);
    addRecoveryTestRoi("S01_Infarct", 40, 0, 2, 5);
    addRecoveryTestRoi("S02_Contralateral", 0, 20, 10, 10);
    addRecoveryTestRoi("S02_Ipsilateral", 20, 20, 9, 10);
    markZeroInfarct(2);
    addRecoveryTestRoi("S03_Contralateral", 0, 40, 10, 10);

    recovered=countRecoverableSlices();
    if (recovered!=2) fail=fail+1;
    lastRecoveredRoi=lastRoiIndexForSlices(recovered);
    deleteRoisFrom(lastRecoveredRoi+1);
    if (roiManager("count")!=5) fail=fail+1;
    rebuildResultsFromRois(sourceTitle, "TEST", 2, recovered);
    if (nResults!=2) fail=fail+1;
    if (abs(getResult("Corrected_Infarct_mm2", 0)-20)>0.000001) fail=fail+1;
    if (abs(getResult("Corrected_Infarct_mm2", 1)-10)>0.000001) fail=fail+1;
    if (getResult("Raw_Infarct_mm2", 1)!=0) fail=fail+1;

    roiManager("reset");
    if (nResults>0) run("Clear Results");
    selectWindow(sourceTitle);
    close();
    if (fail>0) exit("ROI_RECOVERY_SELF_TEST_FAILED: "+fail);
    print("ROI_RECOVERY_SELF_TEST_OK");
}
