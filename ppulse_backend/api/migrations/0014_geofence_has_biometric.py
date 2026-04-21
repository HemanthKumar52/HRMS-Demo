from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0013_add_pay_head_data'),
    ]

    operations = [
        migrations.AddField(
            model_name='geofence',
            name='has_biometric',
            field=models.BooleanField(
                default=False,
                help_text='Office has a biometric device — mobile check-in blocked when inside this zone',
            ),
        ),
    ]
