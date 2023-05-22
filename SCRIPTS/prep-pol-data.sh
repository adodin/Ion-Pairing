#!/bin/bash

counter=1
sub_string=" "
while :; do
   case $1 in
      -swm4ndp)
         sub_string=${sub_string}" s/^$counter .*/& \# ODw/ \n "
         counter=$(( counter + 1 ))
         sub_string=${sub_string}" s/^$counter .*/& \# H/ \n "
         counter=$(( counter + 1 ))
         sub_string=${sub_string}" s/^$counter .*/& \# M/ \n "
         counter=$(( counter + 1 ))
         shift
      ;;
      -CO3)
         sub_string=${sub_string}" s/^$counter .*/& \# C/ \n"
         counter=$(( counter + 1 ))
         sub_string=${sub_string}" s/^$counter .*/& \# Oc/ \n"
         counter=$(( counter + 1 ))
         shift
      ;;
      -*)
         el=$1
         el=${el//-}
         sub_string=${sub_string}" s/^$counter .*/& \# ${el}/ \n"
         counter=$(( counter + 1 ))
         shift
         ;;
      *)
         break
   esac
done

in_file=$1
shift
out_file=$1 
shift

sub_string=$(echo -e ${sub_string})
# Append Atom Names as comments to Masses Section
sed -E "/^Masses/,/^Pair Coeff/{
   ${sub_string}
}

# Delete Pair Coeffs Section
/^Pair Coeffs/,/^Bond Coeffs/{
  /^Bond Coeffs/ !{
     d
  }
}
" $in_file > $out_file