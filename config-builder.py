#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Sileo DEB 包配置生成工具
用于管理dylib到deb的转换配置
"""

import os
import json
import sys
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
from pathlib import Path

class DebConfigBuilder:
    def __init__(self, repo_dir):
        self.repo_dir = repo_dir
        self.tools_dir = os.path.join(repo_dir, "deb-tools")
        os.makedirs(self.tools_dir, exist_ok=True)
        
    def create_config_file(self, dylib_name, config_data):
        """创建配置文件"""
        config_file = os.path.join(self.tools_dir, f"{dylib_name}.conf")
        
        with open(config_file, 'w') as f:
            f.write("#!/bin/bash\n")
            f.write("# 自动生成的deb配置文件\n\n")
            f.write(f"DYLIB_NAME='{dylib_name}'\n")
            f.write(f"PACKAGE_NAME='{config_data['package_name']}'\n")
            f.write(f"PACKAGE_VERSION='{config_data['package_version']}'\n")
            f.write(f"PACKAGE_MAINTAINER='{config_data['maintainer']}'\n")
            f.write(f"PACKAGE_HOMEPAGE='{config_data['homepage']}'\n")
            f.write(f"PACKAGE_DESC='{config_data['description']}'\n")
        
        return config_file
    
    def create_from_gui(self):
        """通过GUI创建配置"""
        root = tk.Tk()
        root.title("DEB 包配置生成器")
        root.geometry("500x600")
        
        # 样式
        root.configure(bg='#f0f0f0')
        
        # 标题
        title = tk.Label(root, text="📦 Sileo DEB 包配置生成器", 
                        font=("Arial", 14, "bold"), bg='#f0f0f0')
        title.pack(pady=10)
        
        # dylib文件
        tk.Label(root, text="dylib文件路径:", bg='#f0f0f0').pack(anchor='w', padx=10, pady=5)
        dylib_var = tk.StringVar()
        dylib_entry = tk.Entry(root, textvariable=dylib_var, width=50)
        dylib_entry.pack(padx=10, pady=5)
        
        def select_dylib():
            file = filedialog.askopenfilename(filetypes=[("dylib files", "*.dylib")])
            if file:
                dylib_var.set(file)
        
        tk.Button(root, text="选择文件", command=select_dylib).pack(pady=5)
        
        # 包名
        tk.Label(root, text="包名 (Package Name):", bg='#f0f0f0').pack(anchor='w', padx=10, pady=5)
        package_var = tk.StringVar()
        tk.Entry(root, textvariable=package_var, width=50).pack(padx=10, pady=5)
        
        # 版本
        tk.Label(root, text="版本号 (Version):", bg='#f0f0f0').pack(anchor='w', padx=10, pady=5)
        version_var = tk.StringVar(value="1.0")
        tk.Entry(root, textvariable=version_var, width=50).pack(padx=10, pady=5)
        
        # 维护者
        tk.Label(root, text="维护者 (Maintainer):", bg='#f0f0f0').pack(anchor='w', padx=10, pady=5)
        maintainer_var = tk.StringVar(value="zxs <applexyz@my.com>")
        tk.Entry(root, textvariable=maintainer_var, width=50).pack(padx=10, pady=5)
        
        # 主页
        tk.Label(root, text="主页 (Homepage):", bg='#f0f0f0').pack(anchor='w', padx=10, pady=5)
        homepage_var = tk.StringVar(value="https://github.com/zxs-ai/repo")
        tk.Entry(root, textvariable=homepage_var, width=50).pack(padx=10, pady=5)
        
        # 描述
        tk.Label(root, text="描述 (Description):", bg='#f0f0f0').pack(anchor='w', padx=10, pady=5)
        desc_text = tk.Text(root, height=4, width=50)
        desc_text.pack(padx=10, pady=5)
        
        def save_config():
            dylib_path = dylib_var.get()
            if not dylib_path or not os.path.exists(dylib_path):
                messagebox.showerror("错误", "请选择有效的dylib文件")
                return
            
            if not package_var.get():
                messagebox.showerror("错误", "请输入包名")
                return
            
            dylib_name = Path(dylib_path).stem
            config_data = {
                'package_name': package_var.get(),
                'package_version': version_var.get(),
                'maintainer': maintainer_var.get(),
                'homepage': homepage_var.get(),
                'description': desc_text.get("1.0", "end").strip()
            }
            
            config_file = self.create_config_file(dylib_name, config_data)
            messagebox.showinfo("成功", f"配置已保存:\n{config_file}")
            
            print(f"\n✅ 配置文件已创建: {config_file}")
            print(f"下一步: ./auto-build-deb.sh {dylib_path}")
            
            root.quit()
        
        tk.Button(root, text="💾 保存配置", command=save_config, 
                 bg='#4CAF50', fg='white', font=("Arial", 12)).pack(pady=20)
        
        root.mainloop()

if __name__ == "__main__":
    repo_dir = os.path.dirname(os.path.abspath(__file__))
    builder = DebConfigBuilder(repo_dir)
    builder.create_from_gui()
