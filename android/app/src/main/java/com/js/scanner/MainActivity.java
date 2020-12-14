package com.js.scanner;

import android.Manifest;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Debug;
import android.view.View;
import android.widget.Toast;

import java.io.File;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;

public class MainActivity extends FlutterActivity implements EasyPermissions.PermissionCallbacks {

    private static final int REQUEST_CODE_QRCODE_PERMISSIONS = 1;
    private static final String CHANNEL = "com.js.scanner";
    private MethodChannel.Result result;

    //    @Override
//    public void configureFlutterEngine(FlutterEngine flutterEngine) {
//        GeneratedPluginRegistrant.registerWith(flutterEngine);
//    }
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        registerBroadcastReceiver();
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        MainActivity.this.result = result;
                        if (call.method.equals("scan")) {
                            startScan();
                        } else if (call.method.equals("launchRoute")) {
                            Double latitude = call.argument("latitude");
                            Double longitude = call.argument("longitude");
                            String address = call.argument("address");

                            Log.d("longitude", longitude.toString());
                            startRoute(latitude, longitude, address);
                        } else {
//                    result.error("", "", null);
//                    MainActivity.this.setResult(null);
                        }
                    }
                });
    }

    public static boolean isAvilible(Context context, String packageName){
        //获取packagemanager   
        final PackageManager packageManager = context.getPackageManager();
        //获取所有已安装程序的包信息   
        List<PackageInfo> packageInfos = packageManager.getInstalledPackages(0);
        //用于存储所有已安装程序的包名   
        List<String> packageNames = new ArrayList<String>();
        //从pinfo中将包名字逐一取出，压入pName list中   
        if(packageInfos != null){
            for(int i = 0; i < packageInfos.size(); i++){
                String packName = packageInfos.get(i).packageName;
                packageNames.add(packName);
            }
        }
        //判断packageNames中是否有目标程序的包名，有TRUE，没有FALSE   
        return packageNames.contains(packageName);
    }

    private void startRoute(Double lat, Double lon, String address) {
        if (isAvilible(this, "com.autonavi.minimap")) {
            try {
                String url = "androidamap://route?sourceApplication=scanner&dpoiname="+ address +"&dlat=" + lat + "&dlon=" + lon + "&dev=0";
               Intent intent = Intent.getIntent(url);
                Log.d("intent", intent.toString());
                Log.d("url", url);
               this.startActivity(intent);
            } catch (URISyntaxException e) {
                e.printStackTrace();
            }
        } else {
            Toast.makeText(this, "您尚未安装高德地图", Toast.LENGTH_LONG).show();
            Uri uri = Uri.parse("market://details?id=com.autonavi.minimap");
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            this.startActivity(intent);
        }
//        act=android.intent.action.VIEW
//        cat=android.intent.category.DEFAULT
//        dat=amapuri://route/plan/?sid=&slat=39.92848272&slon=116.39560823&sname=A&did=&dlat=39.98848272&dlon=116.47560823&dname=B&dev=0&t=0
//        pkg=com.autonavi.minimap

    }

    //注册广播
    private void registerBroadcastReceiver() {
        IntentFilter myIntentFilter = new IntentFilter();
        myIntentFilter.addAction("scan_success");//过滤广播
        myIntentFilter.addAction("scan_cancel");//过滤广播
        registerReceiver(mBroadcastReceiver, myIntentFilter);
    }

    // 得到广播
    private BroadcastReceiver mBroadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (action.equals("scan_success")) {//过滤广播,未登录
                String code = intent.getStringExtra("code");
                MainActivity.this.result.success(code);
                MainActivity.this.result = null;
            } else if (action.equals("scan_cancel")) {
                MainActivity.this.result.success("");
                MainActivity.this.result = null;
            }
        }
    };

    public void startScan() {
        startActivity(new Intent(this, ScannerActivity.class));
    }

    @Override
    protected void onStart() {
        super.onStart();
        requestCodeQRCodePermissions();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, List<String> perms) {
    }

    @Override
    public void onPermissionsDenied(int requestCode, List<String> perms) {
    }

    @AfterPermissionGranted(REQUEST_CODE_QRCODE_PERMISSIONS)
    private void requestCodeQRCodePermissions() {
        String[] perms = {Manifest.permission.CAMERA, Manifest.permission.READ_EXTERNAL_STORAGE};
        if (!EasyPermissions.hasPermissions(this, perms)) {
            EasyPermissions.requestPermissions(this, "扫描二维码需要打开相机和散光灯的权限", REQUEST_CODE_QRCODE_PERMISSIONS, perms);
        }
    }


}