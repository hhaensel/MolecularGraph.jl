#
# This file is a part of graphmol.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    remove_H,
    remove_H!,
    removeall_H,
    removeall_H!,
    removewater,
    removewater!,
    removesalt,
    removesalt!


struct NoImplicitH <: Annotation end
struct NoHydrogen <: Annotation end
struct NoWater <: Annotation end
struct NoPharmSalt <: Annotation end


function remove_H!(mol::MutableMol)
    for (i, a) in mol.graph.nodes
        # TODO: check stereo (SMILES, SDFile)
        if (a.symbol == :H && a.charge == 0 && a.multiplicity == 1
                && a.mass === nothing)
            unlinkatom!(mol, i)
        end
    end
    mol.annotation[:NoImplicitH] = NoImplicitH()
    return
end

function remove_H(mol; use_deepcopy=true)
    mol1 = use_deepcopy ? deepcopy(mol) : copy(mol)
    remove_H!(mol1)
    mol1
end


function removeall_H!(mol::MutableMol)
    required_annotation(mol, :NoImplicitH)
    for (i, a) in mol.graph.nodes
        if a.symbol == :H
            unlinkatom!(mol, i)
        end
    end
    mol.annotation[:NoHydrogen] = NoHydrogen()
    return
end

function removeall_H(mol; use_deepcopy=true)
    mol1 = use_deepcopy ? deepcopy(mol) : copy(mol)
    remove_H!(mol1)
    mol1
end


function removewater!(mol::MapMol)
    required_annotation(mol, :NoImplicitH)
    for (i, a) in mol.graph.nodes
        if a.symbol == :O && neighborcount(mol, i) == 0
            unlinkatom!(mol, i)
        end
    end
    mol.annotation[:NoWater] = NoWater()
    return
end

function removewater(mol; use_deepcopy=true)
    mol1 = use_deepcopy ? deepcopy(mol) : copy(mol)
    removewater!(mol1)
    mol1
end


const SINGLE_ELEM_SALT = [:N, :Na, :Mg, :Al, :Cl, :K, :Ca, :Br, :I]


function removesalt!(mol::MapMol)
    required_annotation(mol, :NoImplicitH)
    for (i, a) in mol.graph.nodes
        if a.symbol in SINGLE_ELEM_SALT && neighborcount(mol, i) == 0
            unlinkatom!(mol, i)
        end
        # TODO: Phosphate, diphosphate, sulfate, nitrate, acetate,
        # maleate, fumarate, succinate, citrate, tartrate, oxalate,
        # mesylate, tosylate, besylate,
        # benzoate, gluconate
    end
    mol.annotation[:NoPharmSalt] = NoPharmSalt()
    return
end

function removesalt(mol; use_deepcopy=true)
    mol1 = use_deepcopy ? deepcopy(mol) : copy(mol)
    removesalt!(mol1)
    mol1
end
