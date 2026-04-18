#!/usr/bin/env python3
"""
Symlink Manager - TokyoNight Temalı Türkçe GUI (Zenity Entegrasyonlu)
"""

import tkinter as tk
from tkinter import ttk, messagebox
import subprocess
from pathlib import Path
import threading
from typing import Optional, List, Dict, Any

class TokyoNightColors:
    """TokyoNight Renk Paleti"""
    BG = '#1a1b26'
    BG_DARK = '#16161e'
    BG_HIGHLIGHT = '#292e42'
    FG = '#c0caf5'
    FG_DARK = '#a9b1d6'
    BLUE = '#7aa2f7'
    CYAN = '#7dcfff'
    GREEN = '#9ece6a'
    MAGENTA = '#bb9af7'
    RED = '#f7768e'
    YELLOW = '#e0af68'
    ORANGE = '#ff9e64'
    SELECTION = '#3e68d7'
    COMMENT = '#565f89'

class CustomCheckbutton(ttk.Frame):
    """Özel tasarım Checkbutton"""
    def __init__(self, parent: tk.Widget, text: str, variable: tk.BooleanVar, **kwargs: Any) -> None:
        super().__init__(parent, style='CustomCheck.TFrame')
        _ = kwargs  # Kullanılmayan argümanları yut
        
        self.variable = variable
        self.text = text
        
        self.check_canvas = tk.Canvas(self, width=20, height=20, 
                                      bg=TokyoNightColors.BG, 
                                      highlightthickness=0)
        self.check_canvas.pack(side=tk.LEFT, padx=(0, 8))
        
        self.label = tk.Label(self, text=text, 
                             bg=TokyoNightColors.BG, 
                             fg=TokyoNightColors.FG,
                             font=('Sans', 10),
                             cursor='hand2')
        self.label.pack(side=tk.LEFT)
        
        self.check_canvas.bind('<Button-1>', self.toggle)
        self.label.bind('<Button-1>', self.toggle)
        
        self.update_display()
        self.variable.trace_add('write', self.on_variable_changed)
        
    def toggle(self, event: Optional[tk.Event] = None) -> None:
        """Değeri tersine çevir"""
        _ = event  # Kullanılmayan event parametresi
        self.variable.set(not self.variable.get())
        
    def on_variable_changed(self, *args: Any) -> None:
        """Değişken değiştiğinde göstergeyi güncelle"""
        _ = args  # Kullanılmayan args
        self.update_display()
        
    def update_display(self) -> None:
        """Göstergeyi güncelle"""
        self.check_canvas.delete('all')
        c = TokyoNightColors()
        
        self.check_canvas.create_rectangle(2, 2, 18, 18, 
                                          outline=c.CYAN, 
                                          width=2,
                                          fill=c.BG_DARK if not self.variable.get() else c.CYAN)
        
        if self.variable.get():
            self.check_canvas.create_line(6, 10, 9, 14, fill=c.BG_DARK, width=2)
            self.check_canvas.create_line(9, 14, 14, 6, fill=c.BG_DARK, width=2)
            
        # Hover efekti
        def on_enter(e: tk.Event) -> None:
            _ = e
            if not self.variable.get():
                self.check_canvas.create_rectangle(2, 2, 18, 18, 
                                                  outline=c.BLUE, 
                                                  width=2)
                
        def on_leave(e: tk.Event) -> None:
            _ = e
            if not self.variable.get():
                self.check_canvas.create_rectangle(2, 2, 18, 18, 
                                                  outline=c.CYAN, 
                                                  width=2)
                
        self.check_canvas.bind('<Enter>', on_enter)
        self.check_canvas.bind('<Leave>', on_leave)

class SymlinkManager:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Symlink Yöneticisi - TokyoNight")
        self.root.geometry("850x700")
        self.root.attributes('-type', 'dialog')
        
        self.source_path = tk.StringVar()
        self.target_path = tk.StringVar()
        self.custom_name = tk.StringVar()
        self.include_hidden = tk.BooleanVar(value=False)
        self.symlink_only_files = tk.BooleanVar(value=False)
        self.follow_symlinks = tk.BooleanVar(value=True)
        self.single_file_mode = tk.BooleanVar(value=False)
        
        self.last_directory = str(Path.home())
        
        # Zenity kontrolü
        self.use_zenity = self.check_command('zenity')
        
        self.setup_tokyonight_style()
        self.setup_ui()
        self.center_window()
        self.source_path.trace_add('write', self.on_source_changed)
        
    def check_command(self, cmd: str) -> bool:
        """Komutun sistemde olup olmadığını kontrol et"""
        try:
            subprocess.run(['which', cmd], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
            
    def select_path(self, title: str, directory: bool = False) -> Optional[str]:
        """Dosya/klasör seçimi"""
        if self.use_zenity:
            return self.select_with_zenity(title, directory)
        else:
            return self.select_with_tkinter(title, directory)
            
    def select_with_zenity(self, title: str, directory: bool = False) -> Optional[str]:
        """Zenity ile seçim"""
        try:
            if directory:
                cmd = ['zenity', '--file-selection', '--directory',
                      '--filename=' + self.last_directory, '--title=' + title,
                      '--width=800', '--height=600']
            else:
                cmd = ['zenity', '--file-selection',
                      '--filename=' + self.last_directory, '--title=' + title,
                      '--width=800', '--height=600']
                
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip():
                selected = result.stdout.strip()
                self.last_directory = str(Path(selected).parent if not directory else selected)
                return selected
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        return None
        
    def select_with_tkinter(self, title: str, directory: bool = False) -> Optional[str]:
        """Tkinter ile seçim (yedek)"""
        from tkinter import filedialog
        
        if directory:
            return filedialog.askdirectory(
                title=title,
                mustexist=True,
                initialdir=self.last_directory
            )
        else:
            return filedialog.askopenfilename(
                title=title,
                initialdir=self.last_directory
            )
            
    def setup_tokyonight_style(self) -> None:
        """TokyoNight teması için stil ayarları"""
        style = ttk.Style()
        style.theme_use('clam')
        c = TokyoNightColors()
        
        style.configure('TFrame', background=c.BG)
        style.configure('CustomCheck.TFrame', background=c.BG)
        style.configure('TLabel', background=c.BG, foreground=c.FG, font=('Sans', 10))
        style.configure('TLabelframe', background=c.BG, foreground=c.CYAN, 
                       borderwidth=1, relief='solid')
        style.configure('TLabelframe.Label', background=c.BG, foreground=c.CYAN, 
                       font=('Sans', 10, 'bold'))
        
        style.configure('TButton', 
                       background=c.BG_HIGHLIGHT, 
                       foreground=c.FG,
                       borderwidth=1,
                       focusthickness=0,
                       font=('Sans', 10))
        style.map('TButton',
                 background=[('active', c.SELECTION),
                           ('pressed', c.BLUE)],
                 foreground=[('active', c.FG),
                           ('pressed', c.FG)])
        
        style.configure('Primary.TButton',
                       background=c.CYAN,
                       foreground=c.BG_DARK,
                       font=('Sans', 10, 'bold'))
        style.map('Primary.TButton',
                 background=[('active', c.BLUE),
                           ('pressed', c.GREEN)],
                 foreground=[('active', c.BG_DARK),
                           ('pressed', c.BG_DARK)])
        
        style.configure('Danger.TButton',
                       background=c.RED,
                       foreground=c.BG_DARK)
        style.map('Danger.TButton',
                 background=[('active', c.ORANGE),
                           ('pressed', c.RED)],
                 foreground=[('active', c.BG_DARK),
                           ('pressed', c.BG_DARK)])
        
        style.configure('Path.TEntry',
                       fieldbackground=c.BG_DARK,
                       foreground=c.FG,
                       borderwidth=1,
                       relief='solid')
        
        style.configure('Header.TLabel', 
                       font=('Sans', 14, 'bold'),
                       foreground=c.CYAN)
        
        style.configure('TProgressbar',
                       background=c.CYAN,
                       troughcolor=c.BG_DARK,
                       borderwidth=0)
        
        style.configure('TRadiobutton',
                       background=c.BG,
                       foreground=c.FG)
        style.map('TRadiobutton',
                 background=[('active', c.BG)],
                 foreground=[('active', c.CYAN)])
        
        self.root.configure(bg=c.BG)
        
    def setup_ui(self) -> None:
        """Ana arayüzü oluştur"""
        c = TokyoNightColors()
        
        main_frame = ttk.Frame(self.root, padding="25")
        main_frame.grid(row=0, column=0, sticky="nsew")
        
        # Başlık
        title_frame = ttk.Frame(main_frame)
        title_frame.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        title_label = ttk.Label(title_frame, text="🔗 Symlink Yöneticisi", 
                               style='Header.TLabel')
        title_label.pack()
        
        if self.use_zenity:
            selector_text = "✨ Dosya seçici: Zenity (Wayland uyumlu)"
        else:
            selector_text = "📦 Dosya seçici: Tkinter"
            
        selector_label = ttk.Label(title_frame, 
                                  text=selector_text,
                                  foreground=c.COMMENT,
                                  font=('Sans', 9))
        selector_label.pack()
        
        subtitle_label = ttk.Label(title_frame, 
                                  text="Dosya ve klasörleri sembolik bağlantı olarak kopyalayın",
                                  foreground=c.COMMENT,
                                  font=('Sans', 9))
        subtitle_label.pack()
        
        # Kaynak seçimi
        source_label_frame = ttk.LabelFrame(main_frame, text="📁 Kaynak", padding="15")
        source_label_frame.grid(row=1, column=0, columnspan=3, sticky="ew", pady=(0, 15))
        
        source_type_frame = ttk.Frame(source_label_frame)
        source_type_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Radiobutton(source_type_frame, text="📂 Klasör (tüm içerik)", 
                       variable=self.single_file_mode, value=False,
                       command=self.on_mode_changed).pack(side=tk.LEFT, padx=(0, 20))
        
        ttk.Radiobutton(source_type_frame, text="📄 Tek Dosya", 
                       variable=self.single_file_mode, value=True,
                       command=self.on_mode_changed).pack(side=tk.LEFT)
        
        source_frame = ttk.Frame(source_label_frame)
        source_frame.pack(fill=tk.X)
        
        self.source_entry = ttk.Entry(source_frame, textvariable=self.source_path, 
                                      style='Path.TEntry', font=('Monospace', 10))
        self.source_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 10))
        
        self.source_button = ttk.Button(source_frame, text="📂 Gözat", 
                                       command=self.browse_source, width=12)
        self.source_button.pack(side=tk.RIGHT)
        
        # Hedef klasör
        target_label_frame = ttk.LabelFrame(main_frame, text="📂 Hedef Klasör", padding="15")
        target_label_frame.grid(row=2, column=0, columnspan=3, sticky="ew", pady=(0, 15))
        
        target_frame = ttk.Frame(target_label_frame)
        target_frame.pack(fill=tk.X)
        
        self.target_entry = ttk.Entry(target_frame, textvariable=self.target_path, 
                                      style='Path.TEntry', font=('Monospace', 10))
        self.target_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 10))
        
        ttk.Button(target_frame, text="📂 Gözat", command=self.browse_target, 
                  width=12).pack(side=tk.RIGHT)
        
        # Özel isim
        self.custom_name_frame = ttk.LabelFrame(main_frame, text="✏️ Özel Symlink İsmi", padding="15")
        self.custom_name_frame.grid(row=3, column=0, columnspan=3, sticky="ew", pady=(0, 15))
        
        custom_frame = ttk.Frame(self.custom_name_frame)
        custom_frame.pack(fill=tk.X)
        
        ttk.Label(custom_frame, text="Symlink adı:").pack(side=tk.LEFT, padx=(0, 10))
        
        self.custom_name_entry = ttk.Entry(custom_frame, textvariable=self.custom_name, 
                                          style='Path.TEntry', font=('Monospace', 10))
        self.custom_name_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        ttk.Label(custom_frame, text="(boş bırakılırsa orijinal isim kullanılır)", 
                 foreground=c.COMMENT, font=('Sans', 9)).pack(side=tk.LEFT, padx=(10, 0))
        
        self.custom_name_frame.grid_remove()
        
        # Seçenekler
        self.options_frame = ttk.LabelFrame(main_frame, text="⚙️ Seçenekler", padding="15")
        self.options_frame.grid(row=4, column=0, columnspan=3, sticky="ew", pady=(0, 15))
        
        options_left = ttk.Frame(self.options_frame)
        options_left.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        options_right = ttk.Frame(self.options_frame)
        options_right.pack(side=tk.RIGHT, fill=tk.X, expand=True)
        
        self.hidden_check = CustomCheckbutton(options_left, 
                                             "🔒 Gizli dosyaları da ekle (.ile başlayanlar)", 
                                             self.include_hidden)
        self.hidden_check.pack(anchor=tk.W, pady=5)
        
        self.only_files_check = CustomCheckbutton(options_left, 
                                                 "📄 Sadece dosyaları symlinkle (klasörleri atla)", 
                                                 self.symlink_only_files)
        self.only_files_check.pack(anchor=tk.W, pady=5)
        
        self.follow_check = CustomCheckbutton(options_right, 
                                             "🔄 Symlink'leri takip et (gerçek yolu kullan)", 
                                             self.follow_symlinks)
        self.follow_check.pack(anchor=tk.W, pady=5)
        
        # Önizleme
        preview_frame = ttk.LabelFrame(main_frame, text="👁️ Önizleme", padding="15")
        preview_frame.grid(row=5, column=0, columnspan=3, sticky="nsew", pady=(0, 15))
        
        list_frame = ttk.Frame(preview_frame)
        list_frame.pack(fill=tk.BOTH, expand=True)
        
        self.preview_listbox = tk.Listbox(list_frame, 
                                         bg=c.BG_DARK, 
                                         fg=c.FG,
                                         selectbackground=c.SELECTION,
                                         selectforeground=c.FG,
                                         height=10,
                                         font=('Monospace', 9),
                                         relief='flat',
                                         borderwidth=0,
                                         highlightthickness=0)
        self.preview_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        self.scrollbar = tk.Scrollbar(list_frame, orient=tk.VERTICAL, 
                                      command=self.preview_listbox.yview,
                                      bg=c.BG_HIGHLIGHT,
                                      troughcolor=c.BG_DARK,
                                      activebackground=c.SELECTION,
                                      width=12,
                                      relief='flat',
                                      borderwidth=0,
                                      highlightthickness=0)
        self.scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.preview_listbox.config(yscrollcommand=self.scrollbar.set)
        
        self.stats_label = ttk.Label(preview_frame, text="", 
                                     foreground=c.COMMENT,
                                     font=('Sans', 9))
        self.stats_label.pack(pady=(5, 0))
        
        # Butonlar
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=6, column=0, columnspan=3, pady=(10, 0))
        
        left_buttons = ttk.Frame(button_frame)
        left_buttons.pack(side=tk.LEFT)
        
        ttk.Button(left_buttons, text="🔄 Önizleme Yap", 
                  command=self.preview).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(left_buttons, text="📎 Symlink Oluştur", 
                  command=self.create_symlinks,
                  style='Primary.TButton').pack(side=tk.LEFT, padx=5)
        
        right_buttons = ttk.Frame(button_frame)
        right_buttons.pack(side=tk.RIGHT)
        
        ttk.Button(right_buttons, text="🗑️ Temizle", 
                  command=self.clear_all).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(right_buttons, text="❌ Çıkış", 
                  command=self.root.quit,
                  style='Danger.TButton').pack(side=tk.LEFT, padx=5)
        
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate', length=400)
        self.progress.grid(row=7, column=0, columnspan=3, pady=(10, 0))
        
        # Grid ağırlıkları
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(5, weight=1)
        
    def on_mode_changed(self) -> None:
        """Tek dosya/klasör modu değiştiğinde"""
        if self.single_file_mode.get():
            self.source_button.config(text="📄 Dosya Seç")
            self.custom_name_frame.grid()
            self.options_frame.grid_remove()
            self.include_hidden.set(False)
            self.symlink_only_files.set(False)
        else:
            self.source_button.config(text="📂 Gözat")
            self.custom_name_frame.grid_remove()
            self.options_frame.grid()
            self.custom_name.set("")
            
    def on_source_changed(self, *args: Any) -> None:
        """Kaynak yol değiştiğinde otomatik önizleme"""
        _ = args  # Kullanılmayan args
        if self.single_file_mode.get() and self.source_path.get():
            source = Path(self.source_path.get())
            if source.is_file():
                if not self.custom_name.get():
                    self.custom_name.set(source.name)
            self.last_directory = str(source.parent)
        elif self.source_path.get():
            self.last_directory = self.source_path.get()
        
    def center_window(self) -> None:
        """Pencereyi ekranın ortasına yerleştir"""
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() // 2) - (width // 2)
        y = (self.root.winfo_screenheight() // 2) - (height // 2)
        self.root.geometry(f'{width}x{height}+{x}+{y}')
        
    def browse_source(self) -> None:
        """Kaynak seçme diyaloğu"""
        if self.single_file_mode.get():
            file_path = self.select_path("Kaynak Dosyayı Seçin", directory=False)
            if file_path:
                self.source_path.set(file_path)
                self.custom_name.set(Path(file_path).name)
        else:
            directory = self.select_path("Kaynak Klasörü Seçin", directory=True)
            if directory:
                self.source_path.set(directory)
            
    def browse_target(self) -> None:
        """Hedef klasör seçme diyaloğu"""
        directory = self.select_path("Hedef Klasörü Seçin", directory=True)
        if directory:
            self.target_path.set(directory)
            
    def get_items_to_link(self) -> List[Dict[str, str]]:
        """Symlink oluşturulacak öğelerin listesini döndür"""
        if not self.source_path.get():
            return []
            
        items = []
        try:
            source = Path(self.source_path.get())
            
            if not source.exists():
                messagebox.showerror("Hata", "Kaynak mevcut değil!")
                return []
                
            if self.single_file_mode.get():
                if source.is_file():
                    if self.custom_name.get():
                        items.append({
                            'source_name': source.name,
                            'target_name': self.custom_name.get()
                        })
                    else:
                        items.append({
                            'source_name': source.name,
                            'target_name': source.name
                        })
                else:
                    messagebox.showerror("Hata", "Lütfen geçerli bir dosya seçin!")
                    return []
            else:
                for item in source.iterdir():
                    name = item.name
                    
                    if not self.include_hidden.get() and name.startswith('.'):
                        continue
                        
                    if self.symlink_only_files.get() and item.is_dir():
                        continue
                        
                    items.append({
                        'source_name': name,
                        'target_name': name
                    })
                
            return sorted(items, key=lambda x: x['target_name'])
            
        except PermissionError:
            messagebox.showerror("Yetki Hatası", "Bu konuma erişim izniniz yok!")
            return []
        except Exception as e:
            messagebox.showerror("Hata", f"Dosyalar listelenirken bir hata oluştu:\n{str(e)}")
            return []
            
    def preview(self) -> None:
        """Önizleme listesini güncelle"""
        if not self.source_path.get():
            messagebox.showwarning("Uyarı", "Lütfen kaynak seçin!")
            return
            
        if not self.target_path.get():
            messagebox.showwarning("Uyarı", "Lütfen hedef klasör seçin!")
            return
            
        items = self.get_items_to_link()
        
        self.preview_listbox.delete(0, tk.END)
        
        if not items:
            self.preview_listbox.insert(tk.END, "⚠️ Gösterilecek dosya veya klasör bulunamadı")
            self.stats_label.config(text="")
        else:
            self.preview_listbox.insert(tk.END, f"📁 Kaynak: {self.source_path.get()}")
            self.preview_listbox.insert(tk.END, f"📂 Hedef:  {self.target_path.get()}")
            
            if self.single_file_mode.get() and self.custom_name.get():
                self.preview_listbox.insert(tk.END, f"✏️ Özel isim: {self.custom_name.get()}")
                
            self.preview_listbox.insert(tk.END, "─" * 60)
            
            files = 0
            folders = 0
            total_size = 0
            
            source_path = Path(self.source_path.get())
            
            for item in items:
                if self.single_file_mode.get():
                    source_full = source_path
                    display_name = f"{item['source_name']} → {item['target_name']}"
                else:
                    source_full = source_path / item['source_name']
                    display_name = item['target_name']
                    
                if source_full.is_dir():
                    self.preview_listbox.insert(tk.END, f"  📁 {display_name}/")
                    folders += 1
                else:
                    size = source_full.stat().st_size
                    total_size += size
                    size_str = self.format_size(size)
                    self.preview_listbox.insert(tk.END, f"  📄 {display_name} ({size_str})")
                    files += 1
                    
            stats_text = f"📊 Toplam: {len(items)} öğe"
            if folders > 0:
                stats_text += f" | 📁 Klasör: {folders}"
            if files > 0:
                stats_text += f" | 📄 Dosya: {files}"
            if total_size > 0:
                stats_text += f" | 💾 Boyut: {self.format_size(total_size)}"
            self.stats_label.config(text=stats_text)
            
    def format_size(self, size: int) -> str:
        """Dosya boyutunu okunabilir formata çevir"""
        size_float = float(size)  # float'a çevir
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_float < 1024.0:
                return f"{size_float:.1f} {unit}"
            size_float /= 1024.0
        return f"{size_float:.1f} TB"
        
    def create_symlinks(self) -> None:
        """Symlink oluşturma işlemini başlat"""
        if not self.source_path.get() or not self.target_path.get():
            messagebox.showwarning("Uyarı", "Lütfen kaynak ve hedef klasörleri seçin!")
            return
            
        items = self.get_items_to_link()
        
        if not items:
            messagebox.showinfo("Bilgi", "Symlink oluşturulacak dosya veya klasör bulunamadı!")
            return
            
        if self.single_file_mode.get():
            if self.custom_name.get():
                message = (f"'{Path(self.source_path.get()).name}' dosyası için "
                          f"'{self.custom_name.get()}' isminde sembolik bağlantı oluşturulacak.\n\n")
            else:
                message = "1 dosya sembolik bağlantı olarak kopyalanacak.\n\n"
        else:
            message = f"{len(items)} öğe sembolik bağlantı olarak kopyalanacak.\n\n"
            
        message += (f"📁 Kaynak: {self.source_path.get()}\n"
                   f"📂 Hedef:  {self.target_path.get()}\n\n"
                   "Devam etmek istiyor musunuz?")
            
        result = messagebox.askyesno("Onay", message)
        
        if not result:
            return
            
        thread = threading.Thread(target=self._create_symlinks_thread, args=(items,))
        thread.daemon = True
        thread.start()
        
    def _create_symlinks_thread(self, items: List[Dict[str, str]]) -> None:
        """Symlink oluşturma işlemini arka planda yap"""
        self.root.after(0, lambda: self.progress.start())
        self.root.after(0, lambda: self.preview_listbox.delete(0, tk.END))
        self.root.after(0, lambda: self.preview_listbox.insert(tk.END, "🔄 Sembolik bağlantılar oluşturuluyor..."))
        self.root.after(0, lambda: self.preview_listbox.insert(tk.END, ""))
        
        başarılı = 0
        başarısız = 0
        atlandı = 0
        
        source_path = Path(self.source_path.get())
        target_path = Path(self.target_path.get())
        
        for item in items:
            if self.single_file_mode.get():
                source = source_path
                target = target_path / item['target_name']
            else:
                source = source_path / item['source_name']
                target = target_path / item['target_name']
            
            try:
                if self.follow_symlinks.get():
                    source_resolved = source.resolve()
                else:
                    source_resolved = source.absolute()
                
                if target.exists():
                    if target.is_symlink():
                        target.unlink()
                    else:
                        atlandı += 1
                        durum = "⚠️ (hedef zaten mevcut)"
                        self.root.after(0, lambda i=item, d=durum: self._add_preview_item(i, d))
                        continue
                
                target.symlink_to(source_resolved)
                başarılı += 1
                durum = "✅"
                
            except PermissionError:
                başarısız += 1
                durum = "❌ (yetki hatası)"
            except Exception as e:
                başarısız += 1
                durum = f"❌ ({str(e)[:40]})"
            else:
                durum = "✅"
                
            self.root.after(0, lambda i=item, d=durum: self._add_preview_item(i, d))
            
        self.root.after(0, lambda: self._finish_operation(başarılı, başarısız, atlandı))
        
    def _add_preview_item(self, item: Dict[str, str], durum: str) -> None:
        """Önizleme listesine bir öğe ekle"""
        if 'source_name' in item and item['source_name'] != item['target_name']:
            display = f"{item['source_name']} → {item['target_name']}"
        else:
            display = item.get('target_name', item.get('source_name', ''))
        self.preview_listbox.insert(tk.END, f"  {durum} {display}")
        self.preview_listbox.see(tk.END)
        
    def _finish_operation(self, başarılı: int, başarısız: int, atlandı: int) -> None:
        """İşlem tamamlandığında UI'ı güncelle"""
        self.progress.stop()
        
        self.preview_listbox.insert(tk.END, "")
        self.preview_listbox.insert(tk.END, "─" * 60)
        
        if başarısız == 0 and atlandı == 0:
            self.preview_listbox.insert(tk.END, "✅ İşlem başarıyla tamamlandı!")
        else:
            self.preview_listbox.insert(tk.END, "⚠️ İşlem bazı uyarılarla tamamlandı")
            
        self.preview_listbox.insert(tk.END, f"   ✅ Başarılı: {başarılı}")
        
        if başarısız > 0:
            self.preview_listbox.insert(tk.END, f"   ❌ Başarısız: {başarısız}")
            
        if atlandı > 0:
            self.preview_listbox.insert(tk.END, f"   ⚠️ Atlanan: {atlandı}")
            
        try:
            if self.single_file_mode.get() and başarılı == 1:
                subprocess.run(['notify-send', '-i', 'dialog-information', 
                              'Symlink Yöneticisi', 
                              '✅ Tek dosya symlink\'i başarıyla oluşturuldu!'], 
                             check=False)
            elif başarısız == 0 and atlandı == 0:
                subprocess.run(['notify-send', '-i', 'dialog-information', 
                              'Symlink Yöneticisi', 
                              f'✅ İşlem başarıyla tamamlandı!\n{başarılı} öğe symlink olarak oluşturuldu.'], 
                             check=False)
            else:
                subprocess.run(['notify-send', '-i', 'dialog-warning', 
                              'Symlink Yöneticisi', 
                              f'⚠️ İşlem tamamlandı\n✅ {başarılı} | ❌ {başarısız} | ⚠️ {atlandı}'], 
                             check=False)
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
            
    def clear_all(self) -> None:
        """Tüm alanları temizle"""
        self.source_path.set("")
        self.target_path.set("")
        self.custom_name.set("")
        self.preview_listbox.delete(0, tk.END)
        self.include_hidden.set(False)
        self.symlink_only_files.set(False)
        self.follow_symlinks.set(True)
        self.single_file_mode.set(False)
        self.stats_label.config(text="")
        self.on_mode_changed()
        self.last_directory = str(Path.home())
        
def main() -> None:
    """Ana fonksiyon"""
    root = tk.Tk()
    
    try:
        root.iconbitmap(default='/usr/share/icons/hicolor/32x32/apps/system-file-manager.png')
    except tk.TclError:
        pass
        
    SymlinkManager(root)
    root.mainloop()
    
if __name__ == "__main__":
    main()
