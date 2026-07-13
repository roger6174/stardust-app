import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { Upload, X, FileText, Loader2, CheckCircle, AlertTriangle, ShieldCheck } from 'lucide-react';
import axios from 'axios';

const API = process.env.REACT_APP_API_URL || 'http://13.126.194.9:5001/api';

const DocumentUploadZone = ({ user, onComplete }) => {
    const [selectedFile, setSelectedFile] = useState(null);
    const [previewUrl, setPreviewUrl] = useState(null);
    const [title, setTitle] = useState('');
    const [uploading, setUploading] = useState(false);
    const [status, setStatus] = useState(null); // 'success', 'error'
    const [progress, setProgress] = useState(0);

    const onDrop = useCallback((acceptedFiles) => {
        if (acceptedFiles.length === 0) return;
        const file = acceptedFiles[0];
        setSelectedFile(file);
        setTitle(file.name.split('.').slice(0, -1).join('.') || file.name); // Default title from filename
        
        if (file.type.startsWith('image/')) {
            setPreviewUrl(URL.createObjectURL(file));
        } else {
            setPreviewUrl(null);
        }
        setStatus(null);
    }, []);

    const handleSave = async () => {
        if (!selectedFile) return;
        const file = selectedFile;
        const formData = new FormData();
        formData.append('file', file);
        formData.append('folder', 'documents');

        setUploading(true);
        setStatus(null);
        setProgress(0);

        try {
            const token = user?.token || localStorage.getItem('stardust_token');
            const response = await axios.post(`${API}/uploads`, formData, {
                headers: { 
                    'Authorization': `Bearer ${token}`
                },
                onUploadProgress: (progressEvent) => {
                    const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                    setProgress(percentCompleted);
                }
            });

            const fileData = response.data.file;

            // NEW: Create the asset record in the database so it appears in the gallery
            await axios.post(`${API}/assets`, {
                category: 'Documents',
                title: title.trim() || file.name,
                metadata: {
                    filename: fileData.filename,
                    originalname: file.name,
                    mimetype: fileData.mimetype,
                    size: fileData.size,
                    location: fileData.location,
                    uploaded_at: new Date().toISOString()
                }
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });

            setStatus('success');
            setTimeout(() => {
                setStatus(null);
                setUploading(false);
                setSelectedFile(null);
                setPreviewUrl(null);
                setTitle('');
                if (onComplete) onComplete();
            }, 2000);
        } catch (error) {
            console.error('Upload Error:', error);
            setStatus('error');
            setTimeout(() => setStatus(null), 3000);
        } finally {
            if (status !== 'success') setUploading(false);
        }
    };

    const cancelSelection = () => {
        setSelectedFile(null);
        setPreviewUrl(null);
        setTitle('');
    };

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        accept: {
            'image/*': ['.jpeg', '.jpg', '.png'],
            'application/pdf': ['.pdf']
        },
        multiple: false
    });

    if (selectedFile && status !== 'success') {
        return (
            <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
                <div className="bg-[var(--bg-app)] border border-[var(--border)] rounded-[2.5rem] p-6 shadow-xl relative overflow-hidden group">
                    <div className="flex flex-col md:flex-row gap-6 items-center">
                        {/* Preview Area */}
                        <div className="w-full md:w-32 h-32 rounded-2xl bg-[var(--surface)] border border-[var(--border)] flex items-center justify-center overflow-hidden shrink-0 group-hover:border-indigo-500/30 transition-all">
                            {previewUrl ? (
                                <img src={previewUrl} alt="Preview" className="w-full h-full object-cover" />
                            ) : (
                                <div className="flex flex-col items-center gap-2 text-[var(--text-secondary)] opacity-40">
                                    <FileText size={32} />
                                    <span className="text-[8px] font-black uppercase tracking-widest">{selectedFile.name.split('.').pop()}</span>
                                </div>
                            )}
                        </div>

                        {/* Title & Info */}
                        <div className="flex-1 space-y-3 w-full">
                            <div className="space-y-1">
                                <label className="text-[9px] font-black text-[var(--text-secondary)] uppercase tracking-[0.2em] ml-1">Document Title</label>
                                <input 
                                    type="text" 
                                    value={title}
                                    onChange={(e) => setTitle(e.target.value)}
                                    placeholder="e.g. Identity Card"
                                    className="w-full bg-[var(--surface-glass)] border border-[var(--border)] rounded-xl px-4 py-3 text-sm font-bold text-[var(--text-primary)] focus:border-indigo-500/50 focus:bg-[var(--surface)] transition-all outline-none"
                                />
                            </div>
                            <div className="flex items-center justify-between px-1">
                                <span className="text-[9px] font-bold text-[var(--text-secondary)] lowercase opacity-60 tracking-widest">
                                    {(selectedFile.size / 1024).toFixed(1)} KB • {selectedFile.type.split('/').pop().toUpperCase()}
                                </span>
                                <button onClick={cancelSelection} className="text-[9px] font-black text-red-500/60 hover:text-red-500 uppercase tracking-widest transition-colors">
                                    Cancel
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Progress Bar Overlay when uploading */}
                    {uploading && (
                        <div className="absolute inset-0 bg-[var(--bg-app)]/90 backdrop-blur-sm flex flex-col items-center justify-center z-10 p-8">
                            <div className="w-full max-w-xs space-y-3">
                                <div className="flex items-center justify-between text-[10px] font-black uppercase tracking-widest text-indigo-500">
                                    <span>Uploading to S3</span>
                                    <span>{progress}%</span>
                                </div>
                                <div className="h-1.5 w-full bg-indigo-500/10 rounded-full overflow-hidden">
                                    <motion.div 
                                        initial={{ width: 0 }}
                                        animate={{ width: `${progress}%` }}
                                        className="h-full bg-indigo-500 shadow-[0_0_12px_rgba(99,102,241,0.5)]"
                                    />
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                <div className="flex gap-3">
                    <button 
                        onClick={handleSave}
                        disabled={uploading || !title.trim()}
                        className={`flex-1 btn-primary h-14 rounded-2xl gap-3 shadow-indigo-500/20 ${(!title.trim() || uploading) ? 'opacity-50 grayscale cursor-not-allowed' : ''}`}
                    >
                        {uploading ? <Loader2 size={18} className="animate-spin" /> : <CheckCircle size={18} />}
                        <span className="uppercase tracking-widest text-[11px] font-black">{uploading ? 'Processing...' : 'Save to Vault'}</span>
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            <div 
                {...getRootProps()} 
                className={`relative group cursor-pointer h-[180px] rounded-[2.5rem] border-2 border-dashed transition-all flex flex-col items-center justify-center p-6 text-center overflow-hidden
                    ${isDragActive ? 'border-indigo-500 bg-indigo-500/10' : 'border-[var(--border)] bg-[var(--bg-app)] hover:bg-[var(--surface)] hover:border-indigo-500/30'}`}
            >
                <input {...getInputProps()} />
                
                {status === 'success' ? (
                    <div className="flex flex-col items-center space-y-2 animate-bounce">
                        <CheckCircle className="w-12 h-12 text-emerald-500 shadow-[0_0_20px_rgba(16,185,129,0.3)]" />
                        <span className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">Vault Secured</span>
                    </div>
                ) : status === 'error' ? (
                    <div className="flex flex-col items-center space-y-2 text-red-500">
                        <AlertTriangle className="w-12 h-12" />
                        <span className="text-[10px] font-black uppercase tracking-widest text-red-500/70">Upload Failed</span>
                    </div>
                ) : (
                    <>
                        <div className="w-14 h-14 rounded-[1.25rem] bg-indigo-500/5 flex items-center justify-center text-indigo-500 mb-3 group-hover:scale-110 group-hover:bg-indigo-500/10 transition-all duration-500">
                            <Upload size={28} />
                        </div>
                        <span className="text-sm font-black uppercase tracking-[0.1em] text-[var(--text-primary)] transition-colors">
                            {isDragActive ? "Infiltrating Box..." : "Upload Document"}
                        </span>
                        <span className="text-[10px] font-bold text-[var(--text-secondary)] mt-1 uppercase tracking-widest opacity-60">Drag PDF or Image</span>
                    </>
                )}
            </div>
            
            <div className="flex items-center gap-3 px-6 py-4 bg-[var(--bg-app)] border border-[var(--border)] rounded-2xl opacity-50">
                <ShieldCheck className="text-indigo-500" size={16} />
                <span className="text-[10px] font-black text-[var(--text-secondary)] uppercase tracking-widest">End-to-End Encrypted Storage</span>
            </div>
        </div>
    );
};

export default DocumentUploadZone;
