```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <!-- Custom scheme: myapp://note/<id> -->
  <data android:scheme="myapp" android:host="note"/>
</intent-filter>
```
