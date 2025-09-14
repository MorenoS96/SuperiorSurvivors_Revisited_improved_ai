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

    -- self.parent.player:Say( tostring(self.parent:needToFollow()) ..",".. tostring(self.parent:getDangerSeenCount() > 0) ..",".. tostring(self.parent.LastEnemeySeen) ..",".. tostring(not self.parent.LastEnemeySeen:isDead()) ..",".. tostring(self.parent:HasInjury() == false) )
    if (not self.parent:needToFollow()) and ((self.parent:getDangerSeenCount() > 0) or
        (self.parent:isEnemyInRange(self.parent.LastEnemeySeen) and self.parent:hasWeapon())) and
        (self.parent.LastEnemeySeen) and not self.parent.LastEnemeySeen:isDead() and (self.parent:HasInjury() == false) then
        return false
    else
        if theDistance < 1 then
            self.parent:StopWalk()
        end
        return true
    end
end

function AttackTask:isValid()
    if (not self.parent) or (not self.parent.LastEnemeySeen) or
        (not self.parent:isInSameRoom(self.parent.LastEnemeySeen)) or (self.parent.LastEnemeySeen:isDead()) then
        return false
    else
        return true
    end
end

function AttackTask:update()
    if not self:isValid() or self:isComplete() then
        return false
    end

    local weapon = self.parent.player:getPrimaryHandItem()
    local theDistance = getDistanceBetween(self.parent.LastEnemeySeen, self.parent.player)
    local minrange = self.parent:getMinWeaponRange()
    local NPC_AttackRange = self.parent:isEnemyInRange(self.parent.LastEnemeySeen)

    -- Decide whether NPC should run or walk
    self.parent:NPC_ShouldRunOrWalk()

    -- Movement management (only if walking is permitted)
    if self.parent:isWalkingPermitted() then
        self.parent:NPC_MovementManagement() -- Melee/positioning
        if self.parent:hasGun() then
            if self.parent:needToReadyGun(weapon) then
                self.parent:ReadyGun(weapon)
            else
                self.parent:NPC_MovementManagement_Guns() -- Move around for shooting
            end
        end
        self.parent:NPC_ManageLockedDoors()
    end

    -- Decide if NPC is in attack range
    if NPC_AttackRange or theDistance < 0.65 then
        -- VEHICLE SHOOTING
        if self.parent:InVehicle() and self.parent:hasGun() and CanShootFromVehicle(self.parent) then
            if self.parent:Is_AtkTicksZero() then
                self.parent:VehicleAttack(self.parent.LastEnemeySeen)
            else
                self.parent:AtkTicks_Countdown()
            end

            -- ON-FOOT GUN ATTACK
        elseif self.parent:hasGun() then
            if self.parent:needToReadyGun(weapon) then
                self.parent:ReadyGun(weapon)
            else
                if self.parent:Is_AtkTicksZero() then
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

    elseif self.parent:isWalkingPermitted() then
        -- Keep moving closer if not in range
        self.parent:NPC_MovementManagement()
    else
        self.parent:DebugSay("ATTACK TASK - something is wrong")
    end

    return true
end
