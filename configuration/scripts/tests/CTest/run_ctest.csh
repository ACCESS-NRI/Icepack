#!/usr/bin/csh

set initargv = ( $argv[*] )

set dash = "-"
set submit_only=0

# Read in command line arguments
set argv = ( $initargv[*] )

while (1)
  if ( $#argv < 1 ) break;
  if ("$argv[1]" == "${dash}submit") then
    set submit_only=1
    shift argv
    continue
  endif
end

if ( $submit_only == 0 ) then
  ctest -S steer.cmake
else
  # Find the filename to submit to CDash
  set CTEST_TAG="`head -n 1 Testing/TAG.submit`"
  
cat > submit.cmake << EOF0
cmake_minimum_required(VERSION 2.8)
set(CTEST_DASHBOARD_ROOT   "\$ENV{PWD}")
set(CTEST_SOURCE_DIRECTORY "\$ENV{PWD}")
set(CTEST_BINARY_DIRECTORY "\$ENV{PWD}")
message("source directory = \${CTEST_SOURCE_DIRECTORY}")

include( CTestConfig.cmake )

ctest_start("Experimental")
ctest_submit(FILES "`pwd`/Testing/${CTEST_TAG}/Test.xml")
EOF0
  ctest -S submit.cmake
endif

if ( $submit_only == 0 ) then
  if ( -f Testing/TAG ) then
    set file='Testing/TAG'
    set CTEST_TAG="`head -n 1 $file`"

    # Check to see if ctest_submit was successful
    set success=0
    set submit_file="Testing/Temporary/LastSubmit_$CTEST_TAG.log"
    foreach line ("`cat $submit_file`")
        if ( "$line" =~ *'Submission successful'* ) then
            set success=1
        endif
    end

    if ( $success == 0 ) then
        echo ""
        set xml_file="Testing/$CTEST_TAG/Test.xml"
        cp Testing/TAG Testing/TAG.submit
        tar czf icepack_ctest.tgz run_ctest.csh CTestConfig.cmake Testing/TAG.submit \
                                      Testing/${CTEST_TAG}/Test.xml
        echo "CTest submission failed.  To try the submission again run "
        echo "    ./run_ctest.csh -submit"
        echo "If you wish to submit the test results from another server, copy the "
        echo "icepack_ctest.tgz file to another server and run "
        echo "    ./run_ctest.csh -submit"
    else
        echo "Submit Succeeded"
    endif
  else
    echo "No Testing/TAG file exists.  Ensure that ctest is installed on this system."
  endif
endif
