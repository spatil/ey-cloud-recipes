ey-postgrecipes
===============

Issues
=======
Under rails you'll see an error like this.

    Please install the postgres adapter: `gem install
    activerecord-postgres-adapter` (no such file to load --
    active_record/connection_adapters/postgres_adapter)

You'll need to modify cookbooks/postgres/templates/default/database.yml.erb and
set the adapter to 'postgresql' instead of 'postgres'.  Just fork the project
and do yo thang.
