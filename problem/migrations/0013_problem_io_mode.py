# Generated by Django 2.1.7 on 2019-03-12 07:13

import django.contrib.postgres.fields.jsonb
from django.db import migrations
import problem.models


class Migration(migrations.Migration):
    dependencies = [
        ('problem', '0012_auto_20180501_0436'),
    ]

    operations = [
        migrations.AddField(
            model_name='problem',
            name='io_mode',
            field=django.contrib.postgres.fields.jsonb.JSONField(
                default=problem.models._default_io_mode
            ),
        ),
    ]
