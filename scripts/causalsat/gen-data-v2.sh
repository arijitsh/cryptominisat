#!/bin/bash

# Copyright (C) 2009-2020 Authors of CryptoMiniSat, see AUTHORS file
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

# This file wraps CMake invocation for TravisCI
# so we can set different configurations via environment variables.

set -e
set -x
set -o pipefail  # needed so  " | tee xyz " doesn't swallow the last command's error

source ./setparams_ballofcrystal.sh

if [ "$1" == "--skip" ]; then
    echo "Will skip running CMS stats + FRAT"
    SKIP="1"
    NEXT_OP="$2"
else
    SKIP="0"
    NEXT_OP="$1"
fi

if [ "$NEXT_OP" == "" ]; then
    while true; do
        echo "No CNF command line parameter, running predefined CNFs"
        echo "Options are:"
        echo "1 -- velev-pipe-uns-1.0-9.cnf"
        echo "2 -- goldb-heqc-i10mul.cnf"
        echo "3 -- Haystacks-ext-13_c18.cnf"
        echo "4 -- NONE"
        echo "5 -- AProVE07-16.cnf"
        echo "6 -- UTI-20-10p0.cnf-unz"
        echo "7 -- UCG-20-5p0.cnf"

        read -r -p "Which CNF do you want to run? " myinput
        case $myinput in
            ["1"]* )
                FNAME="velev-pipe-uns-1.0-9.cnf"
                break;;
            [2]* )
                FNAME="goldb-heqc-i10mul.cnf";
                break;;
            [3]* )
                FNAME="dist6.c-sc2018.cnf";
                break;;
            [5]* )
                FNAME="AProVE07-16.cnf";
                break;;
            [6]* )
                DUMPRATIO="0.01"
                FNAME="UTI-20-10p0.cnf-unz";
                FIXED="20000";
                break;;
            [7]* )
                DUMPRATIO="0.50"
                FNAME="UCG-20-5p0.cnf";
                break;;
            * ) echo "Please answer 1-7";;
        esac
    done
else
    if [ "$NEXT_OP" == "-h" ] || [ "$NEXT_OP" == "--help" ]; then
        echo "You must give a CNF file as input"
        exit
    fi
    initial="$(echo ${NEXT_OP} | head -c 1)"
    if [ "$1" == "-" ]; then
        echo "Cannot understand opion, there are no options"
        exit 255
    fi
    FNAME="${NEXT_OP}"
fi

set -e
set -o pipefail

echo "--> Running on file                   $FNAME"
echo "--> Outputting to data                $FNAMEOUT"
echo "--> Using clause gather ratio of      $DUMPRATIO"
echo "--> Locking in ratio of               $CLLOCK"
echo "--> with fixed number of data points  $FIXED"

if [ "$FNAMEOUT" == "" ]; then
    echo "Error: FNAMEOUT is not set, it's empty. Exiting."
    exit 255
fi


if [ "$SKIP" != "1" ]; then
    echo "Cleaning up"
    (
    rm -rf "$FNAME-dir"
    mkdir "$FNAME-dir"
    cd "$FNAME-dir"
    rm -f $FNAMEOUT.d*
    rm -f $FNAMEOUT.lemma*
    )


    (
    ########################
    # Obtain dynamic data in SQLite and FRAT info
    ########################
    cd "$FNAME-dir"
    # for var, we need: --bva 0 --scc 0
    $NOBUF ../cryptominisat5 --maxnummatrices 0 --presimp 1 --cldatadumpratio "$DUMPRATIO" --cllockdatagen "$CLLOCK" --clid --sql 2 --sqlitedboverwrite 1 --zero-exit-status "../$FNAME" "$FNAMEOUT.frat" | tee cms-pred-run.out
    grep "c conflicts" cms-pred-run.out

    ########################
    # Run frat-rs
    ########################
    set +e
    grep "s SATIS" cms-pred-run.out > /dev/null
    retval=$?
    set -e
    if [[ retval -eq 1 ]]; then
        /usr/bin/time -v ../frat-rs elab "$FNAMEOUT.frat" "../$FNAME" -m -v

        echo "If the following fails, you MUST compile frat-rs with 'ascii' feature through 'cargo build --features=ascii --release' !"
        set +e
        /usr/bin/time -v ../frat-rs elab "$FNAMEOUT.frat"
        /usr/bin/time -v ../frat-rs refrat "$FNAMEOUT.frat.temp" correct
        set -e


    else
        echo "Not UNSAT!!!"
    fi
    echo "CMS+FRAT done now"
    )
fi


(
set -e
cd "$FNAME-dir"

########################
# Augment, fix up and sample the SQLite data
########################

rm -f "$FNAMEOUT."
rm -f "$FNAMEOUT-min.db"
rm -f "${FNAMEOUT}-min.db-cldata-*"
rm -f out_pred_*
rm -f sample.out
rm -f check_quality.out
rm -f clean_update.out
rm -f fill_clauses.out

# ../fix_up_frat.py correct "$FNAME.sqlite" | tee fill_used_clauses.out
cp ../"$FNAME.sqlite" "$FNAMEOUT.db"
/usr/bin/time -v ../clean_update_data.py "$FNAMEOUT.db"  | tee clean_update_data.out
../check_data_quality.py --slow "$FNAMEOUT.db" | tee check_data_quality.out
cp "$FNAMEOUT.db" "$FNAMEOUT-min.db"
/usr/bin/time -v ../sample_data.py "$FNAMEOUT-min.db" | tee sample_data.out


########################
# Denormalize the data into a Pandas Table, label it and sample it
########################
../cldata_gen_pandas.py "${FNAMEOUT}-min.db" --cut1 "$cut1" --cut2 "$cut2" --limit "$FIXED" ${EXTRA_GEN_PANDAS_OPTS} | tee cldata_gen_pandas.out
# ../vardata_gen_pandas.py "${FNAMEOUT}.db" --limit 1000


####################################
# Clustering for cldata, using cldata dataframe
####################################
# ../clustering.py ${FNAMEOUT}-min.db-cldata-*short*.dat ${FNAMEOUT}-min.db-cldata-*long*.dat --basedir ../../src/predict/ --clusters 4 --scale --nocomputed


####################################
# Create the classifiers
####################################

# TODO: add --csv  to dump CSV
#       then you can play with Weka
#../vardata_predict.py mydata.db-vardata.dat --picktimeonly -q 2 --only 0.99
#../vardata_predict.py vardata-comb --final -q 20 --basedir ../src/predict/ --depth 7 --tree
)
