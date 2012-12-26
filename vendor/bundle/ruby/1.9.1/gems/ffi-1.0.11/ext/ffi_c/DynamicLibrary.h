/*
 * Copyright (c) 2008-2010 Wayne Meissner
 * All rights reserved.
 *
 * This file is part of ruby-ffi.
 *
 * This code is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3 only, as
 * published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
 * version 3 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3 along with this work.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _LIBRARY_H
#define	_LIBRARY_H

#ifdef	__cplusplus
extern "C" {
#endif



typedef struct Library {
    void* handle;
} Library;

extern void rbffi_DynamicLibrary_Init(VALUE ffiModule);

#ifdef	__cplusplus
}
#endif

#endif	/* _LIBRARY_H */

