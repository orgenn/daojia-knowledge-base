#!/usr/bin/env python3
"""
道家经典古籍下载器 - 使用中国哲学书电子化计划API获取纯文本
"""

import os
import re
import json
import urllib.request
import urllib.parse

# 经典书籍列表（直接获取纯文本）
BOOKS = [
    ("道德经", "dao-de-jing"),
    ("清静经", "qing-jing-jing"),
    ("阴符经", "yin-fu-jing"),
    ("黄庭经", "huang-ting-jing"),
    ("抱朴子内篇", "baopuzi-neipian"),
]

def get_text(url):
    """获取纯文本内容"""
    try:
        # 使用text API获取纯文本
        api_url = f"https://api.ctext.org/{url}/zhs?format=text"
        req = urllib.request.Request(api_url)
        req.add_header('User-Agent', 'Mozilla/5.0')
        with urllib.request.urlopen(req, timeout=30) as response:
            return response.read().decode('utf-8')
    except Exception as e:
        print(f"API错误: {e}")
        return None

def save_text(content, filepath):
    """保存文本"""
    if content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    output_dir = "/home/orgen/.openclaw/workspace/projects/道家知识库/07-经典书籍"
    os.makedirs(output_dir, exist_ok=True)
    
    for name, slug in BOOKS:
        print(f"下载: {name}...")
        content = get_text(slug)
        if content and len(content) > 100:
            filepath = os.path.join(output_dir, f"{name}.txt")
            if save_text(content, filepath):
                print(f"✓ 成功: {name} ({len(content)}字符)")
        else:
            print(f"✗ 失败: {name}")

if __name__ == "__main__":
    main()
