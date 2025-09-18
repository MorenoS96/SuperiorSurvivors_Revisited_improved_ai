AttackTask = {}
AttackTask.__index = AttackTask

function AttackTask:new(superSurvivor)

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.parent = superSurvivor
    o.Name = "Attack"
    o.OnGoing = false
    -- o.parent:Speak("starting attack")
    o.parent:DebugSay(tostring(o.parent:getCurrentTask()) .. " Started!")

    return o

end

function AttackTask:isComplete()
    local theDistance = getDistanceBetween(self.Target, self.parent.player)
    if (CanShootFromVehicle(self.parent)) then
        print("AttackTask is not complete - CanShootFromVehicle")
        return false
    end
    -- self.parent.player:Say( tostring(self.parent:needToFollow()) ..",".. tostring(self.parent:getDangerSeenCount() > 0) ..",".. tostring(self.parent.LastEnemeySeen) ..",".. tostring(not self.parent.LastEnemeySeen:isDead()) ..",".. tostring(self.parent:HasInjury() == false) )
    if (not self.parent:needToFollow()) and ((self.parent:getDangerSeenCount() > 0) or
        (self.parent:isEnemyInRange(self.parent.LastEnemeySeen) and self.parent:hasWeapon())) and
        (self.parent.LastEnemeySeen) and not self.parent.LastEnemeySeen:isDead() and (self.parent:HasInjury() == false) then
        print("AttackTask is not complete")
        return false
    else
        return true
    end
end

function AttackTask:isValid()
    if (not self.parent) or (not self.parent.LastEnemeySeen) or (not self.parent:RealCanSee(self.parent.LastEnemeySeen)) or
        (self.parent.LastEnemeySeen:isDead()) then
        print("AttackTask is not valid")
        return false
    else
        print("AttackTask is valid")
        return true
    end
end

function AttackTask:update()
    if not self:isValid() or self:isComplete() then
        self.parent:StopWalk()
        return false
    end
    if (self.parent:isWalkingPermitted()) then
        self.parent:NPC_MovementManagement() -- For melee movement management

        -- Controls the Range of how far / close the NPC should be
        if self.parent:hasGun() then -- Despite the name, it means 'has gun in the npc's hand'
            if (self.parent:needToReadyGun(weapon)) then
                self.parent:ReadyGun(weapon)
            else
                self.parent:NPC_MovementManagement_Guns() -- To move around, it checks for in attack range too
            end
        end
    end

    local weapon = self.parent.player:getPrimaryHandItem()
    local theDistance = getDistanceBetween(self.parent.LastEnemeySeen, self.parent.player)
    local minrange = self.parent:getMinWeaponRange()
    local NPC_AttackRange = self.parent:isEnemyInRange(self.parent.LastEnemeySeen)
    local maxRange = self.parent:getMaxWeaponRange()
    -- Decide whether NPC should run or walk
    self.parent:NPC_ShouldRunOrWalk()
    print("ATTACK sequence")

    -- Decide if NPC is in attack range
    if NPC_AttackRange or theDistance < 0.65 then
        if (not weapon or (not self.parent:usingGun()) or ISReloadWeaponAction.canShoot(weapon)) then

            if self.parent:hasGun() then
                if self.parent:needToReadyGun(weapon) then
                    print("Need to ready gun")
                    self.parent:ReadyGun(weapon)
                else
                    if self.parent:Is_AtkTicksZero() then
                        print("Ranged ATTACK")
                        self.parent:Attack(self.parent.LastEnemeySeen)
                    else
                        self.parent:AtkTicks_Countdown()
                    end
                end

                -- MELEE ATTACK
            else
                if self.parent:Is_AtkTicksZero() then
                    self.parent:NPC_Attack(self.parent.LastEnemeySeen)
                else
                    self.parent:AtkTicks_Countdown()
                end
            end
        end
    elseif self.parent:isWalkingPermitted() then
        self.parent:NPC_ManageLockedDoors()
        -- Keep moving closer if not in range
        -- self.parent:NPC_MovementManagement()
    else
        self.parent:DebugSay("ATTACK TASK - something is wrong")
    end

    return true
end
