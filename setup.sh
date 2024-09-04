if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit
fi

new_name=$1



mv \{\{python_template\}\}/ $new_name/
sed -i -e s/src/$new_name/ setup.py

rm setup.sh
